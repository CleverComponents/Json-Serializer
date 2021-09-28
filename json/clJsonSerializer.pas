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

    procedure SerializeArray(AProperty: TRttiProperty; AObject: TObject;
      Attribute: TclJsonPropertyAttribute; AJson: TclJsonObject);
    procedure DeserializeArray(AProperty: TRttiProperty; AObject: TObject; AJsonArray: TclJSONArray);

    function Deserialize(AType: TClass; const AJson: TclJSONObject): TObject; overload;
    function Deserialize(AObject: TObject; const AJson: TclJSONObject): TObject; overload;
    function Serialize(AObject: TObject): TclJSONObject;
  public
    function JsonToObject(AType: TClass; const AJson: string): TObject; overload; override;
    function JsonToObject(AObject: TObject; const AJson: string): TObject; overload; override;
    function ObjectToJson(AObject: TObject): string; override;
  end;

resourcestring
  cUnsupportedDataType = 'Unsupported data type';
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

    for i := 0 to AJsonArray.Count - 1 do
    begin

      case elType.Kind of
        tkClass:
          if (AJsonArray.Items[i] is TclJSONObject) then begin
            objClass := elType.TypeData.ClassType;
            rItemValue := Deserialize(objClass, TclJSONObject(AJsonArray.Items[i]));
          end;

        tkString, tkLString, tkWString, tkUString:
          rItemValue := AJsonArray.Items[i].ValueString;

        tkInteger:
          rItemValue := StrToInt(AJsonArray.Items[i].ValueString);

        tkInt64:
          rItemValue := StrToInt64(AJsonArray.Items[i].ValueString);

        tkFloat:
          rItemValue := StrToFloat(AJsonArray.Items[i].ValueString);

        tkEnumeration:
          if (elType = System.TypeInfo(Boolean)) and (AJsonArray.Items[i] is TclJSONBoolean) then begin
            rItemValue := TclJSONBoolean(AJsonArray.Items[i]).Value;
          end;

        else
          raise EclJsonSerializerError.Create(cUnsupportedDataType);
      end;

      // if (elType.Kind = tkClass)
      //   and (AJsonArray.Items[i] is TclJSONObject) then
      // begin
      //   objClass := elType.TypeData.ClassType;
      //   rItemValue := Deserialize(objClass, TclJSONObject(AJsonArray.Items[i]));
      // end else
      // if (elType.Kind in [tkString, tkLString, tkWString, tkUString]) then
      // begin
      //   rItemValue := AJsonArray.Items[i].ValueString;
      // end else
      // if (elType.Kind = tkInteger) then
      // begin
      //   rItemValue := StrToInt(AJsonArray.Items[i].ValueString);
      // end else
      // if (elType.Kind = tkInt64) then
      // begin
      //   rItemValue := StrToInt64(AJsonArray.Items[i].ValueString);
      // end else
      // if (elType.Kind = tkEnumeration)
      //   and (elType = System.TypeInfo(Boolean))
      //   and (AJsonArray.Items[i] is TclJSONBoolean) then
      // begin
      //   rItemValue := TclJSONBoolean(AJsonArray.Items[i]).Value;
      // end else
      // begin
      //   raise EclJsonSerializerError.Create(cUnsupportedDataType);
      // end;

      rValue.SetArrayElement(i, rItemValue);
    end;

    AProperty.SetValue(AObject, rValue);
  finally
    DynArrayClear(pArr, AProperty.PropertyType.Handle);
  end;
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

    Result := rValue.AsObject;
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

        case rProp.PropertyType.TypeKind of
          tkDynArray:
            if (member.Value is TclJSONArray) then
              DeserializeArray(rProp, Result, TclJSONArray(member.Value));

          tkClass:
            if (member.Value is TclJSONObject) then begin
              objClass := rProp.PropertyType.Handle^.TypeData.ClassType;
              rValue := Deserialize(objClass, TclJSONObject(member.Value));
              rProp.SetValue(Result, rValue);
            end;

          tkString, tkLString, tkWString, tkUString: begin
            rValue := member.ValueString;
            rProp.SetValue(Result, rValue);
          end;

          tkInteger: begin
            rValue := StrToInt(member.ValueString);
            rProp.SetValue(Result, rValue);
          end;

          tkInt64: begin
            rValue := StrToInt64(member.ValueString);
            rProp.SetValue(Result, rValue);
          end;

          tkFloat: begin
            rValue := StrToFloat(member.ValueString);
            rProp.SetValue(Result, rValue)
          end;

          tkEnumeration:
            if (rProp.GetValue(Result).TypeInfo = System.TypeInfo(Boolean)) and (member.Value is TclJSONBoolean) then begin
              rValue := TclJSONBoolean(member.Value).Value;
              rProp.SetValue(Result, rValue);
            end;

          else
            raise EclJsonSerializerError.Create(cUnsupportedDataType);
        end;

        // if (rProp.PropertyType.TypeKind = tkDynArray)
        //   and (member.Value is TclJSONArray) then
        // begin
        //   DeserializeArray(rProp, Result, TclJSONArray(member.Value));
        // end else
        // if (rProp.PropertyType.TypeKind = tkClass)
        //   and (member.Value is TclJSONObject) then
        // begin
        //   objClass := rProp.PropertyType.Handle^.TypeData.ClassType;
        //   rValue := Deserialize(objClass, TclJSONObject(member.Value));
        //   rProp.SetValue(Result, rValue);
        // end else
        // if (rProp.PropertyType.TypeKind in [tkString, tkLString, tkWString, tkUString]) then
        // begin
        //   rValue := member.ValueString;
        //   rProp.SetValue(Result, rValue);
        // end else
        // if (rProp.PropertyType.TypeKind = tkInteger) then
        // begin
        //   rValue := StrToInt(member.ValueString);
        //   rProp.SetValue(Result, rValue);
        // end else
        // if (rProp.PropertyType.TypeKind = tkInt64) then
        // begin
        //   rValue := StrToInt64(member.ValueString);
        //   rProp.SetValue(Result, rValue);
        // end else
        // if (rProp.PropertyType.TypeKind = tkEnumeration)
        //   and (rProp.GetValue(Result).TypeInfo = System.TypeInfo(Boolean))
        //   and (member.Value is TclJSONBoolean) then
        // begin
        //   rValue := TclJSONBoolean(member.Value).Value;
        //   rProp.SetValue(Result, rValue);
        // end else
        // begin
        //   raise EclJsonSerializerError.Create(cUnsupportedDataType);
        // end;
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
  if (AObject = nil) then begin
    Result := nil;
    Exit;
  end;

  nonSerializable := True;

  ctx := TRttiContext.Create();
  try
    Result := TclJSONObject.Create();
    try
      rType := ctx.GetType(AObject.ClassInfo);
      for rProp in rType.GetProperties() do begin
        GetPropertyAttributes(rProp, propAttr, requiredAttr);

        if (propAttr <> nil) then begin
          nonSerializable := False;

          case rProp.PropertyType.TypeKind of
            tkDynArray:
              SerializeArray(rProp, AObject, TclJsonPropertyAttribute(propAttr), Result);

            tkClass:
              Result.AddMember(TclJsonPropertyAttribute(propAttr).Name, Serialize(rProp.GetValue(AObject).AsObject()));

            tkString, tkLString, tkWString, tkUString:
              if (propAttr is TclJsonStringAttribute) then
                if (requiredAttr <> nil) then
                  Result.AddRequiredString(TclJsonPropertyAttribute(propAttr).Name, rProp.GetValue(AObject).AsString())
                else
                  Result.AddString(TclJsonPropertyAttribute(propAttr).Name, rProp.GetValue(AObject).AsString())
              else
                Result.AddValue(TclJsonPropertyAttribute(propAttr).Name, rProp.GetValue(AObject).AsString());

            tkInteger, tkInt64:
              Result.AddValue(TclJsonPropertyAttribute(propAttr).Name, rProp.GetValue(AObject).ToString());

            tkFloat:
              Result.AddSingle(TclJsonPropertyAttribute(propAttr).Name, rProp.GetValue(AObject).AsType<Single>);

            tkRecord:
              Result.AddMember(TclJsonPropertyAttribute(propAttr).Name, Serialize(rProp.GetValue(AObject)));

            tkEnumeration:
              if rProp.GetValue(AObject).TypeInfo = System.TypeInfo(Boolean) then
                Result.AddBoolean(TclJsonPropertyAttribute(propAttr).Name, rProp.GetValue(AObject).AsBoolean());
          else
            raise EclJsonSerializerError.Create(cUnsupportedDataType);
          end;
        end;
      end;

      if (nonSerializable) then
        raise EclJsonSerializerError.Create(cNonSerializable);
    except
      Result.Free();
      raise;
    end;
  finally
    ctx.Free();
  end;
end;

procedure TclJsonSerializer.SerializeArray(
  AProperty: TRttiProperty;
  AObject: TObject;
  Attribute: TclJsonPropertyAttribute;
  AJson: TclJsonObject);
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

      case rValue.GetArrayElement(i).Kind of
        tkClass:
          arr.Add(Serialize(rValue.GetArrayElement(i).AsObject()));

        tkString, tkLString, tkWString, tkUString:
          if (Attribute is TclJsonStringAttribute) then
            arr.Add(TclJSONString.Create(rValue.GetArrayElement(i).AsString()))
          else
            arr.Add(TclJSONValue.Create(rValue.GetArrayElement(i).AsString()));

        tkInteger, tkInt64:
          arr.Add(TclJSONValue.Create(rValue.GetArrayElement(i).ToString()));

        tkFloat:
          arr.Add(TclJSONSingle.Create(rValue.GetArrayElement(i).AsType<Single>));

        tkEnumeration:
          if (rValue.GetArrayElement(i).TypeInfo = System.TypeInfo(Boolean)) then
            arr.Add(TclJSONBoolean.Create(rValue.GetArrayElement(i).AsBoolean()));

        else
          raise EclJsonSerializerError.Create(cUnsupportedDataType);
      end;

      // if (rValue.GetArrayElement(i).Kind = tkClass) then
      // begin
      //   arr.Add(Serialize(rValue.GetArrayElement(i).AsObject()));
      // end else
      // if (rValue.GetArrayElement(i).Kind in [tkString, tkLString, tkWString, tkUString]) then
      // begin
      //   if (Attribute is TclJsonStringAttribute) then
      //   begin
      //     arr.Add(TclJSONString.Create(rValue.GetArrayElement(i).AsString()));
      //   end else
      //   begin
      //     arr.Add(TclJSONValue.Create(rValue.GetArrayElement(i).AsString()));
      //   end;
      // end else
      // if (rValue.GetArrayElement(i).Kind in [tkInteger, tkInt64]) then
      // begin
      //   arr.Add(TclJSONValue.Create(rValue.GetArrayElement(i).ToString()));
      // end else
      // if (rValue.GetArrayElement(i).Kind = tkEnumeration)
      //   and (rValue.GetArrayElement(i).TypeInfo = System.TypeInfo(Boolean)) then
      // begin
      //   arr.Add(TclJSONBoolean.Create(rValue.GetArrayElement(i).AsBoolean()));
      // end else
      // begin
      //   raise EclJsonSerializerError.Create(cUnsupportedDataType);
      // end;
    end;
  end;
end;

end.
