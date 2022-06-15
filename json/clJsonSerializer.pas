{
  Copyright (C) 2016 by Clever Components

  Author: Sergey Shirokov <admin@clevercomponents.com>

  Website: www.CleverComponents.com

  This file is part of Json Serializer.

  Json Serializer is free software: you can redistribute it and/or modify
  it under the terms of the GNU Lesser General Public License version 3
  as published by the Free Software Foundation and appearing in the
  included file COPYING.LESSER.

  Json Serializer is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU Lesser General Public License for more details.

  You should have received a copy of the GNU Lesser General Public License
  along with Json Serializer. If not, see <http://www.gnu.org/licenses/>.
}

unit clJsonSerializer;

interface

uses
  System.Classes, System.SysUtils, System.Generics.Collections, System.Rtti, System.TypInfo, clJsonSerializerBase, clJsonParser;

type
  TclJsonTypeNameMapAttributeList = TArray<TclJsonTypeNameMapAttribute>;

  TclJsonSerializer = class(TclJsonSerializerBase)
  strict private
    procedure GetTypeAttributes(AType: TRttiType; var ATypeNameAttrs: TclJsonTypeNameMapAttributeList);
    procedure GetPropertyAttributes(AProp: TRttiProperty; var APropAttr: TclJsonPropertyAttribute;
      var ARequiredAttr: TclJsonRequiredAttribute);
    function GetObjectClass(ATypeNameAttrs: TclJsonTypeNameMapAttributeList; AJsonObject: TclJSONObject): TRttiType;
    function EnumNameToTValue(const Name: string; AProperty: TRttiProperty; EnumType: PTypeInfo): TValue;
    function EnumTValueToName(AValue: TValue; AProperty: TRttiProperty): string;

    procedure SerializeArray(AProperty: TRttiProperty; AObject: TObject;
      Attribute: TclJsonPropertyAttribute; AJson: TclJsonObject);
    procedure SerializeMap(AProperty: TRttiProperty; AObject: TObject;
      Attribute: TclJsonPropertyAttribute; AJson: TclJsonObject);
    procedure SerializeList(AProperty: TRttiProperty; AObject: TObject;
      Attribute: TclJsonPropertyAttribute; AJson: TclJsonObject);

    procedure DeserializeArray(AProperty: TRttiProperty; AObject: TObject; AJsonArray: TclJSONArray);
    procedure DeserializeMap(AProperty: TRttiProperty; AObject: TObject; AJsonObject: TclJSONObject);
    procedure DeserializeList(AProperty: TRttiProperty; AObject: TObject; AJsonArray: TclJSONArray);

    function Deserialize(ATypeInfo: PTypeInfo; const AJson: TclJSONObject): TObject; overload;
    function Deserialize(AType: TClass; const AJson: TclJSONObject): TObject; overload;
    function Deserialize(AObject: TObject; const AJson: TclJSONObject): TObject; overload;
    function Serialize(AObject: TObject): TclJSONObject;
  strict protected
    procedure SortMapKeys(var AKeyArray: TValue); virtual;
  public
    function JsonToObject(AType: TClass; const AJson: string): TObject; overload; override;
    function JsonToObject(AObject: TObject; const AJson: string): TObject; overload; override;
    function JsonToObject<T>(const AJson: string): T; overload;
    function ObjectToJson(AObject: TObject): string; override;
  end;

resourcestring
  cUnsupportedDataType = 'Unsupported data type';
  cDictionaryRequired = 'Dictionary type is required to serialize object maps';
  cObjectListRequired = 'ObjectList type is required to serialize object arrays';
  cNonSerializable = 'The object is not serializable';

implementation

{ TclJsonSerializer }

function TclJsonSerializer.GetObjectClass(ATypeNameAttrs: TclJsonTypeNameMapAttributeList; AJsonObject: TclJSONObject): TRttiType;
var
  ctx: TRttiContext;
  typeName: string;
  attr: TclJsonTypeNameMapAttribute;
begin
  Result := nil;
  if (ATypeNameAttrs = nil) or (Length(ATypeNameAttrs) = 0) then Exit;

  typeName := AJsonObject.ValueByName(ATypeNameAttrs[0].PropertyName);
  if (typeName = '') then Exit;

  ctx := TRttiContext.Create();
  try
    for attr in ATypeNameAttrs do
    begin
      if (attr.TypeName = typeName) then
      begin
        Result := ctx.FindType(attr.TypeClassName);
        Exit;
      end;
    end;
  finally
    ctx.Free()
  end;
end;

function TclJsonSerializer.Deserialize(ATypeInfo: PTypeInfo; const AJson: TclJSONObject): TObject;
var
  ctx: TRttiContext;
  lType, rType: TRttiType;
  instType: TRttiInstanceType;
  rValue: TValue;
  typeNameAttrs: TclJsonTypeNameMapAttributeList;
begin
  Result := nil;
  if (AJson.Count = 0) then Exit;

  ctx := TRttiContext.Create();
  try
    rType := ctx.GetType(ATypeInfo);

    GetTypeAttributes(rType, typeNameAttrs);
    lType := GetObjectClass(typeNameAttrs, AJson);
    if (lType = nil) then
    begin
      lType := rType;
    end;
    instType := lType.AsInstance;
    rValue := instType.GetMethod('Create').Invoke(instType.MetaclassType, []);

    Result := rValue.AsObject();
    try
      Result := Deserialize(Result, AJson);
    except
      Result.Free();
      raise;
    end;
  finally
    ctx.Free();
  end;
end;

procedure TclJsonSerializer.DeserializeArray(AProperty: TRttiProperty;
  AObject: TObject; AJsonArray: TclJSONArray);
var
  elType: PTypeInfo;
  len: NativeInt;
  pArr: Pointer;
  rValue, rItemValue: TValue;
  i: Integer;
  objClass: TClass;
begin
  len := AJsonArray.Count;
  if (len = 0) then Exit;

  if (GetTypeData(AProperty.PropertyType.Handle).DynArrElType = nil) then Exit;

  elType := GetTypeData(AProperty.PropertyType.Handle).DynArrElType^;

  pArr := nil;

  DynArraySetLength(pArr, AProperty.PropertyType.Handle, 1, @len);
  try
    TValue.Make(@pArr, AProperty.PropertyType.Handle, rValue);

    for i := 0 to len - 1 do
    begin
      if (elType.Kind = tkClass)
        and (AJsonArray.Items[i] is TclJSONObject) then
      begin
        objClass := elType.TypeData.ClassType;
        rItemValue := Deserialize(objClass, TclJSONObject(AJsonArray.Items[i]));
      end else
      if (elType.Kind in [tkString, tkLString, tkWString, tkUString]) then
      begin
        rItemValue := AJsonArray.Items[i].ValueString;
      end else
      if (elType.Kind = tkInteger) then
      begin
        rItemValue := StrToInt(AJsonArray.Items[i].ValueString);
      end else
      if (elType.Kind = tkInt64) then
      begin
        rItemValue := StrToInt64(AJsonArray.Items[i].ValueString);
      end else
      if (elType.Kind = tkEnumeration)
        and (elType = System.TypeInfo(Boolean))
        and (AJsonArray.Items[i] is TclJSONBoolean) then
      begin
        rItemValue := TclJSONBoolean(AJsonArray.Items[i]).Value;
      end else
      if (elType.Kind = tkEnumeration)
        and (AJsonArray.Items[i] is TclJSONValue) then
      begin
        rItemValue := EnumNameToTValue(AJsonArray.Items[i].ValueString, AProperty, elType);
      end else
      begin
        raise EclJsonSerializerError.Create(cUnsupportedDataType);
      end;

      rValue.SetArrayElement(i, rItemValue);
    end;

    AProperty.SetValue(AObject, rValue);
  finally
    DynArrayClear(pArr, AProperty.PropertyType.Handle);
  end;
end;

procedure TclJsonSerializer.DeserializeList(AProperty: TRttiProperty; AObject: TObject; AJsonArray: TclJSONArray);
var
  i: Integer;
  listType: TRttiInstanceType;
  objectList, itemValue: TValue;
  addMethod: TRttiMethod;
  itemType: TRttiType;
  itemClass: TClass;
begin
  if (AJsonArray.Count = 0) then Exit;

  listType := AProperty.PropertyType.AsInstance;
  addMethod := listType.GetMethod('Add');

  if (addMethod = nil) then
  begin
    raise EclJsonSerializerError.Create(cObjectListRequired);
  end;

  itemType := addMethod.GetParameters[0].ParamType;
  itemClass := itemType.Handle^.TypeData.ClassType;

  objectList := listType.GetMethod('Create').Invoke(listType.MetaclassType, [True]);
  AProperty.SetValue(AObject, objectList);

  for i := 0 to AJsonArray.Count - 1 do
  begin
    if not (AJsonArray.Items[i] is TclJSONObject) then
    begin
      raise EclJsonSerializerError.Create(cUnsupportedDataType);
    end;

    itemValue := Deserialize(itemClass, TclJSONObject(AJsonArray.Items[i]));

    addMethod.Invoke(objectList, [itemValue]);
  end;
end;

procedure TclJsonSerializer.DeserializeMap(AProperty: TRttiProperty;
  AObject: TObject; AJsonObject: TclJSONObject);
var
  i: Integer;
  dictType: TRttiInstanceType;
  mapName, mapObject,
  dictionary, dictOwnerships: TValue;
  addMethod: TRttiMethod;
  itemType: TRttiType;
  itemClass: TClass;
begin
  if (AJsonObject.Count = 0) then Exit;

  //TODO deserialize non-object types, including dynarrays
  dictOwnerships := TValue.From<TDictionaryOwnerships>([doOwnsValues]);
  dictType := AProperty.PropertyType.AsInstance;

  addMethod := dictType.GetMethod('Add');

  if (addMethod = nil) then
  begin
    raise EclJsonSerializerError.Create(cDictionaryRequired);
  end;

  itemType := addMethod.GetParameters[1].ParamType;
  //TODO deserialize non-object types, including dynarrays
  itemClass := itemType.Handle^.TypeData.ClassType;

  //TODO deserialize non-object types, including dynarrays
  dictionary := dictType.GetMethod('Create').Invoke(dictType.MetaclassType, [dictOwnerships, 0]);
  AProperty.SetValue(AObject, dictionary);

  for i := 0 to AJsonObject.Count - 1 do
  begin
    if not (AJsonObject.Members[i].Value is TclJSONObject) then Continue;

    mapName := AJsonObject.Members[i].Name;
    //TODO deserialize non-object types, including dynarrays
    mapObject := Deserialize(itemClass, TclJSONObject(AJsonObject.Members[i].Value));

    addMethod.Invoke(dictionary, [mapName, mapObject]);
  end;
end;

function TclJsonSerializer.EnumNameToTValue(const Name: string;
  AProperty: TRttiProperty; EnumType: PTypeInfo): TValue;
var
  attr: TCustomAttribute;
  names: TArray<string>;
  t: TRttiType;
  V: integer;
begin
  if (AProperty.PropertyType is TRttiDynamicArrayType) then
  begin
    t := TRttiDynamicArrayType(AProperty.PropertyType).ElementType;
  end else
  if (AProperty.PropertyType is TRttiArrayType) then
  begin
    t := TRttiArrayType(AProperty.PropertyType).ElementType;
  end else
  begin
    t := AProperty.PropertyType;
  end;

  for attr in t.GetAttributes() do
  begin
    if (attr is TclJsonEnumNamesAttribute) then
    begin
      names := TclJsonEnumNamesAttribute(attr).Names;
      for V := Low(names) to High(names) do
      begin
        if (Name = names[V]) then
        begin
          TValue.Make(V, EnumType, Result);
          Exit;
        end;
      end;
    end;
  end;

  V:= GetEnumValue(EnumType, Name);
  TValue.Make(V, EnumType, Result);
end;

function TclJsonSerializer.EnumTValueToName(AValue: TValue; AProperty: TRttiProperty): string;
var
  attr: TCustomAttribute;
  names: TArray<string>;
  t: TRttiType;
begin
  if (AProperty.PropertyType is TRttiDynamicArrayType) then
  begin
    t := TRttiDynamicArrayType(AProperty.PropertyType).ElementType;
  end else
  if (AProperty.PropertyType is TRttiArrayType) then
  begin
    t := TRttiArrayType(AProperty.PropertyType).ElementType;
  end else
  begin
    t := AProperty.PropertyType;
  end;

  for attr in t.GetAttributes() do
  begin
    if (attr is TclJsonEnumNamesAttribute) then
    begin
      names := TclJsonEnumNamesAttribute(attr).Names;
      if Length(names) > 0 then
      begin
        Result := names[AValue.AsOrdinal()];
      end;
      Exit;
    end;
  end;

  Result := AValue.ToString();
end;

function TclJsonSerializer.JsonToObject(AObject: TObject; const AJson: string): TObject;
var
  obj: TclJSONObject;
begin
  obj := TclJSONBase.ParseObject(AJson);
  try
    Result := Deserialize(AObject, obj);
  finally
    obj.Free();
  end;
end;

function TclJsonSerializer.JsonToObject<T>(const AJson: string): T;
var
  obj: TclJSONObject;
begin
  obj := TclJSONBase.ParseObject(AJson);
  try
    Result := TValue.From(Deserialize(TypeInfo(T), obj)).AsType<T>;
  finally
    obj.Free();
  end;
end;

function TclJsonSerializer.JsonToObject(AType: TClass; const AJson: string): TObject;
var
  obj: TclJSONObject;
begin
  obj := TclJSONBase.ParseObject(AJson);
  try
    Result := Deserialize(AType, obj);
  finally
    obj.Free();
  end;
end;

function TclJsonSerializer.ObjectToJson(AObject: TObject): string;
var
  json: TclJSONObject;
begin
  json := Serialize(AObject);
  try
    Result := json.GetJSONString();
  finally
    json.Free();
  end;
end;

function TclJsonSerializer.Deserialize(AType: TClass; const AJson: TclJSONObject): TObject;
var
  ctx: TRttiContext;
  lType, rType: TRttiType;
  instType: TRttiInstanceType;
  rValue: TValue;
  typeNameAttrs: TclJsonTypeNameMapAttributeList;
begin
  Result := nil;
  if (AJson.Count = 0) then Exit;

  ctx := TRttiContext.Create();
  try
    rType := ctx.GetType(AType);

    GetTypeAttributes(rType, typeNameAttrs);
    lType := GetObjectClass(typeNameAttrs, AJson);
    if (lType = nil) then
    begin
      lType := rType;
    end;
    instType := lType.AsInstance;
    rValue := instType.GetMethod('Create').Invoke(instType.MetaclassType, []);

    Result := rValue.AsObject();
    try
      Result := Deserialize(Result, AJson);
    except
      Result.Free();
      raise;
    end;
  finally
    ctx.Free();
  end;
end;

function TclJsonSerializer.Deserialize(AObject: TObject; const AJson: TclJSONObject): TObject;
var
  ctx: TRttiContext;
  rType: TRttiType;
  rProp: TRttiProperty;
  member: TclJSONPair;
  rValue: TValue;
  objClass: TClass;
  nonSerializable: Boolean;
  requiredAttr: TclJsonRequiredAttribute;
  propAttr: TclJsonPropertyAttribute;
begin
  Result := AObject;

  if (AJson.Count = 0) or (Result = nil) then Exit;

  nonSerializable := True;

  ctx := TRttiContext.Create();
  try
    rType := ctx.GetType(Result.ClassInfo);

    for rProp in rType.GetProperties() do
    begin
      GetPropertyAttributes(rProp, propAttr, requiredAttr);

      if (propAttr <> nil) then
      begin
        nonSerializable := False;

        member := AJson.MemberByName(TclJsonPropertyAttribute(propAttr).Name);
        if (member = nil) then Continue;

        if (rProp.PropertyType.TypeKind = tkDynArray)
          and (member.Value is TclJSONArray) then
        begin
          DeserializeArray(rProp, Result, TclJSONArray(member.Value));
        end else
        if (rProp.PropertyType.TypeKind = tkClass)
          and (propAttr is TclJsonMapAttribute) then
        begin
          DeserializeMap(rProp, Result, TclJSONObject(member.Value));
        end else
        if (rProp.PropertyType.TypeKind = tkClass)
          and (propAttr is TclJsonListAttribute) then
        begin
          DeserializeList(rProp, Result, TclJSONArray(member.Value));
        end else
        if (rProp.PropertyType.TypeKind = tkClass)
          and (member.Value is TclJSONObject) then
        begin
          objClass := rProp.PropertyType.Handle^.TypeData.ClassType;
          rValue := Deserialize(objClass, TclJSONObject(member.Value));
          rProp.SetValue(Result, rValue);
        end else
        if (rProp.PropertyType.TypeKind in [tkString, tkLString, tkWString, tkUString]) then
        begin
          rValue := member.ValueString;
          rProp.SetValue(Result, rValue);
        end else
        if (rProp.PropertyType.TypeKind = tkInteger) then
        begin
          rValue := StrToInt(member.ValueString);
          rProp.SetValue(Result, rValue);
        end else
        if (rProp.PropertyType.TypeKind = tkInt64) then
        begin
          rValue := StrToInt64(member.ValueString);
          rProp.SetValue(Result, rValue);
        end else
        if (rProp.PropertyType.TypeKind = tkEnumeration)
          and (rProp.GetValue(Result).TypeInfo = System.TypeInfo(Boolean))
          and (member.Value is TclJSONBoolean) then
        begin
          rValue := TclJSONBoolean(member.Value).Value;
          rProp.SetValue(Result, rValue);
        end else
        if (rProp.PropertyType.TypeKind = tkEnumeration)
          and (rProp.GetValue(Result).TypeInfo.Kind = tkEnumeration)
          and (member.Value is TclJSONValue) then
        begin
          rValue := EnumNameToTValue(member.ValueString, rProp, rProp.GetValue(Result).TypeInfo);
          rProp.SetValue(Result, rValue);
        end else
        begin
          raise EclJsonSerializerError.Create(cUnsupportedDataType);
        end;
      end;
    end;
  finally
    ctx.Free();
  end;

  if (nonSerializable) then
  begin
    raise EclJsonSerializerError.Create(cNonSerializable);
  end;
end;

procedure TclJsonSerializer.GetPropertyAttributes(AProp: TRttiProperty; var APropAttr: TclJsonPropertyAttribute;
  var ARequiredAttr: TclJsonRequiredAttribute);
var
  attr: TCustomAttribute;
begin
  APropAttr := nil;
  ARequiredAttr := nil;

  for attr in AProp.GetAttributes() do
  begin
    if (attr is TclJsonPropertyAttribute) then
    begin
      APropAttr := attr as TclJsonPropertyAttribute;
    end else
    if (attr is TclJsonRequiredAttribute) then
    begin
      ARequiredAttr := attr as TclJsonRequiredAttribute;
    end;
  end;
end;

procedure TclJsonSerializer.GetTypeAttributes(AType: TRttiType; var ATypeNameAttrs: TclJsonTypeNameMapAttributeList);
var
  attr: TCustomAttribute;
  list: TList<TclJsonTypeNameMapAttribute>;
begin
  list := TList<TclJsonTypeNameMapAttribute>.Create();
  try
    for attr in AType.GetAttributes() do
    begin
      if (attr is TclJsonTypeNameMapAttribute) then
      begin
        list.Add(attr as TclJsonTypeNameMapAttribute);
      end;
    end;
    ATypeNameAttrs := list.ToArray();
  finally
    list.Free();
  end;
end;

function TclJsonSerializer.Serialize(AObject: TObject): TclJSONObject;
var
  ctx: TRttiContext;
  rType: TRttiType;
  rProp: TRttiProperty;
  nonSerializable: Boolean;
  requiredAttr: TclJsonRequiredAttribute;
  propAttr: TclJsonPropertyAttribute;
begin
  if (AObject = nil) then
  begin
    Result := nil;
    Exit;
  end;

  nonSerializable := True;

  ctx := TRttiContext.Create();
  try
    Result := TclJSONObject.Create();
    try
      rType := ctx.GetType(AObject.ClassInfo);
      for rProp in rType.GetProperties() do
      begin
        GetPropertyAttributes(rProp, propAttr, requiredAttr);

        if (propAttr <> nil) then
        begin
          nonSerializable := False;

          if (rProp.PropertyType.TypeKind = tkDynArray) then
          begin
            SerializeArray(rProp, AObject, TclJsonPropertyAttribute(propAttr), Result);
          end else
          if (rProp.PropertyType.TypeKind = tkClass)
            and (propAttr is TclJsonMapAttribute) then
          begin
            SerializeMap(rProp, AObject, TclJsonPropertyAttribute(propAttr), Result);
          end else
          if (rProp.PropertyType.TypeKind = tkClass)
            and (propAttr is TclJsonListAttribute) then
          begin
            SerializeList(rProp, AObject, TclJsonPropertyAttribute(propAttr), Result);
          end else
          if (rProp.PropertyType.TypeKind = tkClass) then
          begin
            Result.AddMember(TclJsonPropertyAttribute(propAttr).Name, Serialize(rProp.GetValue(AObject).AsObject()));
          end else
          if (rProp.PropertyType.TypeKind in [tkString, tkLString, tkWString, tkUString]) then
          begin
            if (propAttr is TclJsonStringAttribute) then
            begin
              if (requiredAttr <> nil) then
              begin
                Result.AddRequiredString(TclJsonPropertyAttribute(propAttr).Name, rProp.GetValue(AObject).AsString());
              end else
              begin
                Result.AddString(TclJsonPropertyAttribute(propAttr).Name, rProp.GetValue(AObject).AsString());
              end;
            end else
            begin
              Result.AddValue(TclJsonPropertyAttribute(propAttr).Name, rProp.GetValue(AObject).AsString());
            end;
          end else
          if (rProp.PropertyType.TypeKind in [tkInteger, tkInt64]) then
          begin
            Result.AddValue(TclJsonPropertyAttribute(propAttr).Name, rProp.GetValue(AObject).ToString());
          end else
          if (rProp.PropertyType.TypeKind = tkEnumeration)
            and (rProp.GetValue(AObject).TypeInfo = System.TypeInfo(Boolean)) then
          begin
            Result.AddBoolean(TclJsonPropertyAttribute(propAttr).Name, rProp.GetValue(AObject).AsBoolean());
          end else
          if (rProp.PropertyType.TypeKind = tkEnumeration) then
          begin
            Result.AddValue(TclJsonPropertyAttribute(propAttr).Name,
              EnumTValueToName(rProp.GetValue(AObject), rProp));
          end else
          begin
            raise EclJsonSerializerError.Create(cUnsupportedDataType);
          end;
        end;
      end;

      if (nonSerializable) then
      begin
        raise EclJsonSerializerError.Create(cNonSerializable);
      end;
    except
      Result.Free();
      raise;
    end;
  finally
    ctx.Free();
  end;
end;

procedure TclJsonSerializer.SerializeArray(AProperty: TRttiProperty; AObject: TObject;
  Attribute: TclJsonPropertyAttribute; AJson: TclJsonObject);
var
  rValue: TValue;
  i: Integer;
  arr: TclJSONArray;
begin
  rValue := AProperty.GetValue(AObject);

  if (rValue.GetArrayLength() > 0) then
  begin
    arr := TclJSONArray.Create();
    AJson.AddMember(Attribute.Name, arr);

    for i := 0 to rValue.GetArrayLength() - 1 do
    begin
      if (rValue.GetArrayElement(i).Kind = tkClass) then
      begin
        arr.Add(Serialize(rValue.GetArrayElement(i).AsObject()));
      end else
      if (rValue.GetArrayElement(i).Kind in [tkString, tkLString, tkWString, tkUString]) then
      begin
        if (Attribute is TclJsonStringAttribute) then
        begin
          arr.Add(TclJSONString.Create(rValue.GetArrayElement(i).AsString()));
        end else
        begin
          arr.Add(TclJSONValue.Create(rValue.GetArrayElement(i).AsString()));
        end;
      end else
      if (rValue.GetArrayElement(i).Kind in [tkInteger, tkInt64]) then
      begin
        arr.Add(TclJSONValue.Create(rValue.GetArrayElement(i).ToString()));
      end else
      if (rValue.GetArrayElement(i).Kind = tkEnumeration)
        and (rValue.GetArrayElement(i).TypeInfo = System.TypeInfo(Boolean)) then
      begin
        arr.Add(TclJSONBoolean.Create(rValue.GetArrayElement(i).AsBoolean()));
      end else
      if (rValue.GetArrayElement(i).Kind = tkEnumeration) then
      begin
        arr.Add(TclJSONValue.Create(
          EnumTValueToName(rValue.GetArrayElement(i), AProperty)));
      end else
      begin
        raise EclJsonSerializerError.Create(cUnsupportedDataType);
      end;
    end;
  end;
end;

procedure TclJsonSerializer.SerializeList(AProperty: TRttiProperty;
  AObject: TObject; Attribute: TclJsonPropertyAttribute; AJson: TclJsonObject);
var
  i, count: Integer;
  objectList, value: TValue;
  listType: TRttiType;
  countProp: TRttiProperty;
  itemsProp: TRttiIndexedProperty;
  arr: TclJSONArray;
begin
  objectList := AProperty.GetValue(AObject);

  listType := AProperty.PropertyType.AsInstance;
  countProp := listType.GetProperty('Count');
  itemsProp := listType.GetIndexedProperty('Items');

  if (countProp = nil) or (itemsProp = nil) then
  begin
    raise EclJsonSerializerError.Create(cObjectListRequired);
  end;

  count := countProp.GetValue(objectList.AsObject()).AsInteger;
  if (count = 0) then Exit;

  arr := TclJSONArray.Create();
  AJson.AddMember(Attribute.Name, arr);

  for i := 0 to count - 1 do
  begin
    value := itemsProp.GetValue(objectList.AsObject(), [i]);
    if (value.Kind <> tkClass) then
    begin
      raise EclJsonSerializerError.Create(cUnsupportedDataType);
    end;

    arr.Add(Serialize(value.AsObject()));
  end;
end;

procedure TclJsonSerializer.SortMapKeys(var AKeyArray: TValue);
begin
  TArray.Sort<string>(AKeyArray.AsType<TArray<string>>());
end;

procedure TclJsonSerializer.SerializeMap(AProperty: TRttiProperty;
  AObject: TObject; Attribute: TclJsonPropertyAttribute; AJson: TclJsonObject);
var
  dictionary, keys, keyArray, key, value: TValue;
  dictType, keysType: TRttiType;
  keysProp: TRttiProperty;
  itemsProp: TRttiIndexedProperty;
  toArrayMethod: TRttiMethod;
  count, i: Integer;
  map: TclJsonObject;
begin
  dictionary := AProperty.GetValue(AObject);

  dictType := AProperty.PropertyType.AsInstance;
  keysProp := dictType.GetProperty('Keys');
  itemsProp := dictType.GetIndexedProperty('Items');

  if (keysProp = nil) or (itemsProp = nil) then
  begin
    raise EclJsonSerializerError.Create(cDictionaryRequired);
  end;

  keysType := keysProp.PropertyType.AsInstance;
  toArrayMethod := keysType.GetMethod('ToArray');

  if (toArrayMethod = nil) then
  begin
    raise EclJsonSerializerError.Create(cDictionaryRequired);
  end;

  keys := keysProp.GetValue(dictionary.AsObject());
  keyArray := toArrayMethod.Invoke(keys.AsObject(), []);

  count := keyArray.GetArrayLength();
  if (count = 0) then Exit;

  SortMapKeys(keyArray);

  map := TclJSONObject.Create();
  AJson.AddMember(Attribute.Name, map);

  for i := 0 to count - 1 do
  begin
    if not (keyArray.GetArrayElement(i).Kind in [tkString, tkWString, tkLString, tkUString]) then
    begin
      raise EclJsonSerializerError.Create(cUnsupportedDataType);
    end;

    key := keyArray.GetArrayElement(i);
    value := itemsProp.GetValue(dictionary.AsObject(), [key]);

    //TODO serialize non-object types, including dynarrays
    map.AddMember(key.ToString(), Serialize(value.AsObject()));
  end;
end;

end.
