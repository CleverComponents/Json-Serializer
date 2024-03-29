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

unit clJsonSerializerTests;

interface

uses
  System.Classes, System.Generics.Collections, System.SysUtils, TestFramework, clJsonSerializerBase, clJsonSerializer;

type
  TclNotSerializable = class
  strict private
    FName: string;
  public
    property Name: string read FName write FName;
  end;

  TclTestUnsupportedType = class
  strict private
    FFloatValue: Double;
  public
    [TclJsonProperty('floatValue')]
    property FloatValue: Double read FFloatValue write FFloatValue;
  end;

  TclTestUnsupportedArrayType = class
  strict private
    FFloatArray: TArray<Double>;
  public
    [TclJsonProperty('floatArray')]
    property FloatArray: TArray<Double> read FFloatArray write FFloatArray;
  end;

  TclTestSubObject = class
  strict private
    FName: string;
    FValue: string;
  public
    [TclJsonString('name')]
    property Name: string read FName write FName;
    [TclJsonString('value')]
    property Value: string read FValue write FValue;
  end;

  TclTestObject = class
  strict private
    FBooleanValue: Boolean;
    FNonSerializable: string;
    FStringValue: string;
    FValue: string;
    FIntegerValue: Integer;
    FSubObject: TclTestSubObject;
    FIntArray: TArray<Integer>;
    FStrArray: TArray<string>;
    FBoolArray: TArray<Boolean>;
    FObjArray: TArray<TclTestSubObject>;

    procedure SetSubObject(const Value: TclTestSubObject);
    procedure SetObjArray(const Value: TArray<TclTestSubObject>);
  public
    constructor Create;
    destructor Destroy; override;

    [TclJsonString('stringValue')]
    property StringValue: string read FStringValue write FStringValue;

    [TclJsonProperty('integerValue')]
    property IntegerValue: Integer read FIntegerValue write FIntegerValue;

    [TclJsonProperty('value')]
    property Value: string read FValue write FValue;

    [TclJsonProperty('booleanValue')]
    property BooleanValue: Boolean read FBooleanValue write FBooleanValue;

    [TclJsonProperty('subObject')]
    property SubObject: TclTestSubObject read FSubObject write SetSubObject;

    [TclJsonProperty('intArray')]
    property IntArray: TArray<Integer> read FIntArray write FIntArray;

    [TclJsonString('strArray')]
    property StrArray: TArray<string> read FStrArray write FStrArray;

    [TclJsonProperty('boolArray')]
    property BoolArray: TArray<Boolean> read FBoolArray write FBoolArray;

    [TclJsonProperty('objArray')]
    property ObjArray: TArray<TclTestSubObject> read FObjArray write SetObjArray;

    property NonSerializable: string read FNonSerializable write FNonSerializable;
  end;

  [TclJsonTypeNameMap('tag', 'inherited', 'clJsonSerializerTests.TclTestInheritedObject')]
  TclTestBaseObject = class
  strict private
    FTag: string;
    FName: string;
  public
    [TclJsonString('tag')]
    property Tag: string read FTag write FTag;

    [TclJsonString('name')]
    property Name: string read FName write FName;
  end;

  TclTestInheritedObject = class(TclTestBaseObject)
  strict private
    FSubName: string;
  public
    [TclJsonString('subname')]
    property SubName: string read FSubName write FSubName;
  end;

  TclTestMultipleTypeArray = class
  strict private
    FConstructorCalled: Boolean;
    FObjArray: TArray<TclTestBaseObject>;

    procedure SetObjArray(const Value: TArray<TclTestBaseObject>);
  public
    constructor Create;
    destructor Destroy; override;

    [TclJsonProperty('objArray')]
    property ObjArray: TArray<TclTestBaseObject> read FObjArray write SetObjArray;

    property ConstructorCalled: Boolean read FConstructorCalled;
  end;

  TclTestRequiredPropertyObject = class
  strict private
    FRequiredString: string;
  public
    [TclJsonRequired]
    [TclJsonString('required-string')]
    property RequiredString: string read FRequiredString write FRequiredString;
  end;

  TclTestEnum = (teOne, teTwo, teThree);

  [TclJsonEnumNames('one,two,three')]
  TclTestNamedEnum = (tnOne, tnTwo, tnThree);

  TclTestEnumPropertyObject = class
  strict private
    FEnum: TclTestEnum;
    FNamedEnum: TclTestNamedEnum;
    FEnumArray: TArray<TclTestEnum>;
    FNamedEnumArray: TArray<TclTestNamedEnum>;
  public
    constructor Create;
    destructor Destroy; override;

    [TclJsonProperty('enum')]
    property Enum: TclTestEnum read FEnum write FEnum;

    [TclJsonProperty('enumArray')]
    property EnumArray: TArray<TclTestEnum> read FEnumArray write FEnumArray;

    [TclJsonProperty('namedEnum')]
    property NamedEnum: TclTestNamedEnum read FNamedEnum write FNamedEnum;

    [TclJsonProperty('namedEnumArray')]
    property NamedEnumArray: TArray<TclTestNamedEnum> read FNamedEnumArray write FNamedEnumArray;
  end;

  TclMapObjectItem = class
  strict private
    FValue: Integer;
  public
    [TclJsonProperty('value')]
    property Value: Integer read FValue write FValue;
  end;

  TclMapObject = class
  private
    FObjects: TObjectDictionary<string, TclMapObjectItem>;

    procedure SetObjects(const Value: TObjectDictionary<string, TclMapObjectItem>);
  public
    constructor Create;
    destructor Destroy; override;

    [TclJsonMap('objects')]
    property Objects: TObjectDictionary<string, TclMapObjectItem> read FObjects write SetObjects;
  end;

  TclMultipleTypeMapObject = class
  private
    FObjects: TObjectDictionary<string, TclTestBaseObject>;

    procedure SetObjects(const Value: TObjectDictionary<string, TclTestBaseObject>);
  public
    constructor Create;
    destructor Destroy; override;

    [TclJsonMap('objects')]
    property Objects: TObjectDictionary<string, TclTestBaseObject> read FObjects write SetObjects;
  end;

  TclAnyTypePropertyObject = class
  private
    FAny: string;
  public
    [TclJsonProperty('any')]
    property Any: string read FAny write FAny;
  end;


  TclListObjectItem = class
  strict private
    FValue: Integer;
  public
    [TclJsonProperty('value')]
    property Value: Integer read FValue write FValue;
  end;

  TclListObject = class
  private
    FObjects: TObjectList<TclListObjectItem>;

    procedure SetObjects(const Value: TObjectList<TclListObjectItem>);
  public
    constructor Create;
    destructor Destroy; override;

    [TclJsonList('objects')]
    property Objects: TObjectList<TclListObjectItem> read FObjects write SetObjects;
  end;

  TclJsonSerializerTests = class(TTestCase)
  published
    procedure TestDeserialize;
    procedure TestDeserializeCreatedInstance;
    procedure TestSerialize;
    procedure TestUnsupportedType;
    procedure TestNonSerializable;
    procedure TestRequiredProperty;
    procedure TestMultipleTypeArray;
    procedure TestInheritedTypes;
    procedure TestEnumProperty;
    procedure TestMapProperty;
    procedure TestMultipleTypeMap;
    procedure TestNonObjectMapProperty;
    procedure TestArrayMapProperty;
    procedure TestObjectListProperty;
    procedure TestAnyTypeProperty;
  end;

implementation

{ TclJsonSerializerTests }

procedure TclJsonSerializerTests.TestArrayMapProperty;
begin
  CheckTrue(False, 'not implemented');
end;

procedure TclJsonSerializerTests.TestDeserialize;
const
  jsonEtalon = '{"stringValue": "qwe", "integerValue": 123, "value": asd, "booleanValue": true}';
  jsonEtalon2 = '{"stringValue": "qwe", "subObject": {"name": "qwerty"}, "intArray": [111, 222], "strArray": ["val 1", "val 2"], ' +
'"boolArray": [true, false], "objArray": [{"name": "an1"}, {"name": "an2"}]}';

var
  serializer: TclJsonSerializer;
  obj: TclTestObject;
begin
  serializer := nil;
  obj := nil;
  try
    serializer := TclJsonSerializer.Create();

    obj := serializer.JsonToObject(TclTestObject, jsonEtalon) as TclTestObject;

    CheckEquals('qwe', obj.StringValue);
    CheckEquals(123, obj.IntegerValue);
    CheckEquals('asd', obj.Value);
    CheckEquals(True, obj.BooleanValue);

    FreeAndNil(obj);

    obj := serializer.JsonToObject(TclTestObject, jsonEtalon2) as TclTestObject;

    CheckEquals('qwe', obj.StringValue);

    CheckTrue(obj.SubObject <> nil);
    CheckEquals('qwerty', obj.SubObject.Name);

    CheckEquals(2, Length(obj.IntArray));
    CheckEquals(111, obj.IntArray[0]);
    CheckEquals(222, obj.IntArray[1]);

    CheckEquals(2, Length(obj.StrArray));
    CheckEquals('val 1', obj.StrArray[0]);
    CheckEquals('val 2', obj.StrArray[1]);

    CheckEquals(2, Length(obj.BoolArray));
    CheckEquals(True, obj.BoolArray[0]);
    CheckEquals(False, obj.BoolArray[1]);

    CheckEquals(2, Length(obj.ObjArray));

    CheckTrue(obj.ObjArray[0] <> nil);
    CheckEquals('an1', obj.ObjArray[0].Name);

    CheckTrue(obj.ObjArray[1] <> nil);
    CheckEquals('an2', obj.ObjArray[1].Name);
  finally
    obj.Free();
    serializer.Free();
  end;
end;

procedure TclJsonSerializerTests.TestAnyTypeProperty;
const
  jsonEtalon = '{"any": {"name": "qwerty"}}';
var
  serializer: TclJsonSerializer;
  obj: TclAnyTypePropertyObject;
begin
  serializer := nil;
  obj := nil;
  try
    serializer := TclJsonSerializer.Create();

    obj := serializer.JsonToObject<TclAnyTypePropertyObject>(jsonEtalon);

    CheckEquals('{"name": "qwerty"}', obj.Any);
  finally
    obj.Free();
    serializer.Free();
  end;
end;

procedure TclJsonSerializerTests.TestDeserializeCreatedInstance;
const
  jsonEtalon = '{"stringValue": "qwe", "integerValue": 123, "value": asd, "booleanValue": true}';

var
  serializer: TclJsonSerializer;
  obj: TclTestObject;
begin
  serializer := nil;
  obj := nil;
  try
    serializer := TclJsonSerializer.Create();

    obj := TclTestObject.Create();
    obj := serializer.JsonToObject(obj, jsonEtalon) as TclTestObject;

    CheckEquals('qwe', obj.StringValue);
    CheckEquals(123, obj.IntegerValue);
    CheckEquals('asd', obj.Value);
    CheckEquals(True, obj.BooleanValue);
  finally
    obj.Free();
    serializer.Free();
  end;
end;

procedure TclJsonSerializerTests.TestMapProperty;
const
  jsonEtalon = '{"objects": {"obj1": {"value": 1}, "obj2": {"value": 2}}}';
var
  serializer: TclJsonSerializer;
  obj: TclMapObject;
  json: string;
begin
  serializer := nil;
  obj := nil;
  try
    serializer := TclJsonSerializer.Create();
    obj := serializer.JsonToObject<TclMapObject>(jsonEtalon);
    CheckTrue(nil <> obj.Objects);
    CheckEquals(2, obj.Objects.Count);
    CheckTrue(obj.Objects.ContainsKey('obj2'));
    CheckEquals(2, obj.Objects['obj2'].Value);

    json := serializer.ObjectToJson(obj);
    CheckEquals(jsonEtalon, json);
  finally
    obj.Free();
    serializer.Free();
  end;
end;

procedure TclJsonSerializerTests.TestEnumProperty;
var
  serializer: TclJsonSerializer;
  obj: TclTestEnumPropertyObject;
  json: string;
  enumArr: TArray<TclTestEnum>;
  namedEnumArr: TArray<TclTestNamedEnum>;
begin
  serializer := nil;
  obj := nil;
  try
    serializer := TclJsonSerializer.Create();

    obj := TclTestEnumPropertyObject.Create();
    obj.Enum := teTwo;
    obj.NamedEnum := tnTwo;

    SetLength(enumArr, 2);
    obj.EnumArray := enumArr;
    enumArr[0] := teTwo;
    enumArr[1] := teThree;

    SetLength(namedEnumArr, 2);
    obj.NamedEnumArray := namedEnumArr;
    namedEnumArr[0] := tnTwo;
    namedEnumArr[1] := tnThree;

    json := serializer.ObjectToJson(obj);
    CheckEquals(
      '{"enum": teTwo, "enumArray": [teTwo, teThree], "namedEnum": two, "namedEnumArray": [two, three]}',
      json);
    FreeAndNil(obj);

    obj := serializer.JsonToObject(TclTestEnumPropertyObject, json) as TclTestEnumPropertyObject;
    CheckTrue(teTwo = obj.Enum);
    CheckTrue(tnTwo = obj.NamedEnum);

    CheckEquals(2, Length(obj.EnumArray));
    CheckTrue(teTwo = obj.EnumArray[0]);
    CheckTrue(teThree = obj.EnumArray[1]);

    CheckEquals(2, Length(obj.NamedEnumArray));
    CheckTrue(tnTwo = obj.NamedEnumArray[0]);
    CheckTrue(tnThree = obj.NamedEnumArray[1]);

    FreeAndNil(obj);
  finally
    obj.Free();
    serializer.Free();
  end;
end;

procedure TclJsonSerializerTests.TestInheritedTypes;
const
  jsonBase = '{"tag": "base", "name": "base class"}';
  jsonInherited = '{"tag": "inherited", "name": "inherited class", "subname": "inherited subname"}';
var
  serializer: TclJsonSerializer;
  obj: TclTestBaseObject;
  inh: TclTestInheritedObject;
begin
  serializer := nil;
  obj := nil;
  try
    serializer := TclJsonSerializer.Create();

    obj := serializer.JsonToObject(TclTestBaseObject, jsonBase) as TclTestBaseObject;

    CheckEquals('base', obj.Tag);
    CheckEquals('base class', obj.Name);

    FreeAndNil(obj);

    obj := serializer.JsonToObject(TclTestBaseObject, jsonInherited) as TclTestBaseObject;

    inh := obj as TclTestInheritedObject;
    CheckEquals('inherited', inh.Tag);
    CheckEquals('inherited class', inh.Name);
    CheckEquals('inherited subname', inh.SubName);

    FreeAndNil(obj);

    obj := serializer.JsonToObject(TclTestInheritedObject, jsonInherited) as TclTestBaseObject;

    inh := obj as TclTestInheritedObject;
    CheckEquals('inherited', inh.Tag);
    CheckEquals('inherited class', inh.Name);
    CheckEquals('inherited subname', inh.SubName);

    FreeAndNil(obj);
  finally
    obj.Free();
    serializer.Free();
  end;
end;

procedure TclJsonSerializerTests.TestMultipleTypeArray;
const
  jsonEtalon = '{"objArray": [{"tag": "base", "name": "base class"}, {"tag": "inherited", "name": "inherited class", "subname": "inherited subname"}]}';
  jsonEtalonMalformed = '{"objArray": [{"tag-bad": "base", "name": "base class"}, {"tag-bad": "inherited", "name": "inherited class", "subname": "inherited subname"}]}';

var
  serializer: TclJsonSerializer;
  obj: TclTestMultipleTypeArray;
begin
  serializer := nil;
  obj := nil;
  try
    serializer := TclJsonSerializer.Create();

    obj := serializer.JsonToObject(TclTestMultipleTypeArray, jsonEtalon) as TclTestMultipleTypeArray;

    CheckEquals(2, Length(obj.ObjArray));
    CheckEquals('base', obj.ObjArray[0].Tag);
    CheckEquals('base class', obj.ObjArray[0].Name);
    CheckEquals('TclTestBaseObject', obj.ObjArray[0].ClassName);
    CheckEquals('inherited', obj.ObjArray[1].Tag);
    CheckEquals('inherited class', obj.ObjArray[1].Name);
    CheckEquals('TclTestInheritedObject', obj.ObjArray[1].ClassName);
    CheckEquals('inherited subname', (obj.ObjArray[1] as TclTestInheritedObject).SubName);
    CheckEquals(True, obj.ConstructorCalled);

    FreeAndNil(obj);

    obj := serializer.JsonToObject(TclTestMultipleTypeArray, jsonEtalonMalformed) as TclTestMultipleTypeArray;

    CheckEquals(2, Length(obj.ObjArray));
    CheckEquals('', obj.ObjArray[0].Tag);
    CheckEquals('base class', obj.ObjArray[0].Name);
    CheckEquals('TclTestBaseObject', obj.ObjArray[0].ClassName);
    CheckEquals('', obj.ObjArray[1].Tag);
    CheckEquals('inherited class', obj.ObjArray[1].Name);
    CheckEquals('TclTestBaseObject', obj.ObjArray[1].ClassName);

    FreeAndNil(obj);
  finally
    obj.Free();
    serializer.Free();
  end;
end;

procedure TclJsonSerializerTests.TestMultipleTypeMap;
const
  jsonEtalon = '{"objects": {"obj1": {"tag": "base", "name": "base class"}, "obj2": {"subname": "inherited subname", "tag": "inherited", "name": "inherited class"}}}';
var
  serializer: TclJsonSerializer;
  obj: TclMultipleTypeMapObject;
  json: string;
begin
  serializer := nil;
  obj := nil;
  try
    serializer := TclJsonSerializer.Create();
    obj := serializer.JsonToObject<TclMultipleTypeMapObject>(jsonEtalon);
    CheckTrue(nil <> obj.Objects);
    CheckEquals(2, obj.Objects.Count);

    CheckTrue(obj.Objects.ContainsKey('obj1'));
    CheckEquals('base class', obj.Objects['obj1'].Name);
    CheckTrue(TclTestBaseObject = obj.Objects['obj1'].ClassType);

    CheckTrue(obj.Objects.ContainsKey('obj2'));
    CheckEquals('inherited class', obj.Objects['obj2'].Name);
    CheckTrue(TclTestInheritedObject = obj.Objects['obj2'].ClassType);
    CheckEquals('inherited subname', TclTestInheritedObject(obj.Objects['obj2']).SubName);

    json := serializer.ObjectToJson(obj);
    CheckEquals(jsonEtalon, json);
  finally
    obj.Free();
    serializer.Free();
  end;
end;

procedure TclJsonSerializerTests.TestNonObjectMapProperty;
begin
  CheckTrue(False, 'not implemented');
end;

procedure TclJsonSerializerTests.TestNonSerializable;
var
  serializer: TclJsonSerializer;
  obj: TclNotSerializable;
begin
  serializer := nil;
  obj := nil;
  try
    serializer := TclJsonSerializer.Create();

    try
      serializer.JsonToObject(TclNotSerializable, '{"name":"test"}');
      Fail('Non-serializable objects cannot be serialized');
    except
      on EclJsonSerializerError do;
    end;

    obj := TclNotSerializable.Create();
    obj.Name := 'test';
    try
      serializer.ObjectToJson(obj);
      Fail('Non-serializable objects cannot be serialized');
    except
      on EclJsonSerializerError do;
    end;
  finally
    obj.Free();
    serializer.Free();
  end;
end;

procedure TclJsonSerializerTests.TestObjectListProperty;
const
  jsonEtalon = '{"objects": [{"value": 1}, {"value": 2}]}';
var
  serializer: TclJsonSerializer;
  obj: TclListObject;
  json: string;
begin
  serializer := nil;
  obj := nil;
  try
    serializer := TclJsonSerializer.Create();
    obj := serializer.JsonToObject<TclListObject>(jsonEtalon);
    CheckTrue(nil <> obj.Objects);
    CheckEquals(2, obj.Objects.Count);
    CheckEquals(2, obj.Objects[1].Value);

    json := serializer.ObjectToJson(obj);
    CheckEquals(jsonEtalon, json);
  finally
    obj.Free();
    serializer.Free();
  end;
end;

procedure TclJsonSerializerTests.TestRequiredProperty;
var
  serializer: TclJsonSerializer;
  obj: TclTestRequiredPropertyObject;
begin
  serializer := nil;
  obj := nil;
  try
    serializer := TclJsonSerializer.Create();

    obj := serializer.JsonToObject(TclTestRequiredPropertyObject, '{"required-string": "qwe"}') as TclTestRequiredPropertyObject;
    CheckEquals('qwe', obj.RequiredString);
    FreeAndNil(obj);

    obj := serializer.JsonToObject(TclTestRequiredPropertyObject, '{"required-string": ""}') as TclTestRequiredPropertyObject;
    CheckEquals('', obj.RequiredString);
    CheckEquals('{"required-string": ""}', serializer.ObjectToJson(obj));
    FreeAndNil(obj);
  finally
    obj.Free();
    serializer.Free();
  end;
end;

procedure TclJsonSerializerTests.TestSerialize;
const
  jsonEtalon = '{"stringValue": "qwe", "integerValue": 123, "value": asd, "booleanValue": true}';
  jsonEtalon2 = '{"stringValue": "qwe", "integerValue": 123, "value": asd, "booleanValue": true, ' +
'"subObject": {"name": "qwerty"}, "intArray": [111, 222], "strArray": ["val 1", "val 2"], ' +
'"boolArray": [true, false], "objArray": [{"name": "an1"}, {"name": "an2"}]}';

var
  serializer: TclJsonSerializer;
  obj: TclTestObject;
  json: string;
  intArr: TArray<Integer>;
  strArr: TArray<string>;
  boolArr: TArray<Boolean>;
  objArr: TArray<TclTestSubObject>;
begin
  serializer := nil;
  obj := nil;
  try
    serializer := TclJsonSerializer.Create();
    obj := TclTestObject.Create();

    obj.StringValue := 'qwe';
    obj.IntegerValue := 123;
    obj.Value := 'asd';
    obj.BooleanValue := True;
    obj.NonSerializable := 'zxc';

    json := serializer.ObjectToJson(obj);

    CheckEquals(jsonEtalon, json);

    obj.SubObject := TclTestSubObject.Create();
    obj.SubObject.Name := 'qwerty';

    SetLength(intArr, 2);
    obj.IntArray := intArr;
    intArr[0] := 111;
    intArr[1] := 222;

    SetLength(strArr, 2);
    obj.StrArray := strArr;
    strArr[0] := 'val 1';
    strArr[1] := 'val 2';

    SetLength(boolArr, 2);
    obj.BoolArray := boolArr;
    boolArr[0] := True;
    boolArr[1] := False;

    SetLength(objArr, 2);
    obj.ObjArray := objArr;
    objArr[0] := TclTestSubObject.Create();
    objArr[0].Name := 'an1';
    objArr[1] := TclTestSubObject.Create();
    objArr[1].Name := 'an2';

    json := serializer.ObjectToJson(obj);

    CheckEquals(jsonEtalon2, json);
  finally
    obj.Free();
    serializer.Free();
  end;
end;

procedure TclJsonSerializerTests.TestUnsupportedType;
var
  serializer: TclJsonSerializer;
  obj: TclTestUnsupportedType;
  objArr: TclTestUnsupportedArrayType;
  arr: TArray<Double>;
begin
  serializer := nil;
  obj := nil;
  objArr := nil;
  try
    serializer := TclJsonSerializer.Create();

    obj := TclTestUnsupportedType.Create();
    obj.FloatValue := 12.5;

    try
      serializer.ObjectToJson(obj);
      Fail('Data type checking does not work');
    except
      on EclJsonSerializerError do;
    end;
    FreeAndNil(obj);

    try
      obj := serializer.JsonToObject(TclTestUnsupportedType, '{"floatValue": 12}') as TclTestUnsupportedType;
      Fail('Data type checking does not work');
    except
      on EclJsonSerializerError do;
    end;
    FreeAndNil(obj);

    objArr := TclTestUnsupportedArrayType.Create();
    SetLength(arr, 1);
    objArr.FloatArray := arr;
    objArr.FloatArray[0] := 12.5;

    try
      serializer.ObjectToJson(objArr);
      Fail('Data type checking does not work');
    except
      on EclJsonSerializerError do;
    end;
    FreeAndNil(objArr);

    try
      objArr := serializer.JsonToObject(TclTestUnsupportedArrayType, '{"floatArray": [11, 22]}') as TclTestUnsupportedArrayType;
      Fail('Data type checking does not work');
    except
      on EclJsonSerializerError do;
    end;
  finally
    objArr.Free();
    obj.Free();
    serializer.Free();
  end;
end;

{ TclTestObject }

constructor TclTestObject.Create;
begin
  inherited Create();

  FSubObject := nil;
  FIntArray := nil;
  FStrArray := nil;
  FBoolArray := nil;
  FObjArray := nil;
end;

destructor TclTestObject.Destroy;
begin
  ObjArray := nil;
  BoolArray := nil;
  StrArray := nil;
  IntArray := nil;
  SubObject := nil;

  inherited Destroy();
end;

procedure TclTestObject.SetObjArray(const Value: TArray<TclTestSubObject>);
var
  obj: TObject;
begin
  if (FObjArray <> nil) then
  begin
    for obj in FObjArray do
    begin
      obj.Free();
    end;
  end;

  FObjArray := Value;
end;

procedure TclTestObject.SetSubObject(const Value: TclTestSubObject);
begin
  FSubObject.Free();
  FSubObject := Value;
end;

{ TclTestMultipleTypeArray }

constructor TclTestMultipleTypeArray.Create;
begin
  inherited Create();

  FObjArray := nil;
  FConstructorCalled := True;
end;

destructor TclTestMultipleTypeArray.Destroy;
begin
  ObjArray := nil;
  inherited Destroy();
end;

procedure TclTestMultipleTypeArray.SetObjArray(const Value: TArray<TclTestBaseObject>);
var
  obj: TObject;
begin
  if (FObjArray <> nil) then
  begin
    for obj in FObjArray do
    begin
      obj.Free();
    end;
  end;

  FObjArray := Value;
end;

{ TclTestEnumPropertyObject }

constructor TclTestEnumPropertyObject.Create;
begin
  inherited Create();

  FEnumArray := nil;
  FNamedEnumArray := nil;
end;

destructor TclTestEnumPropertyObject.Destroy;
begin
  NamedEnumArray := nil;
  EnumArray := nil;

  inherited Destroy();
end;

{ TclMapObject }

constructor TclMapObject.Create;
begin
  inherited Create();
  FObjects := nil;
end;

destructor TclMapObject.Destroy;
begin
  Objects := nil;
  inherited Destroy();
end;

procedure TclMapObject.SetObjects(const Value: TObjectDictionary<string, TclMapObjectItem>);
begin
  FObjects.Free();
  FObjects := Value;
end;

{ TclMultipleTypeMapObject }

constructor TclMultipleTypeMapObject.Create;
begin
  inherited Create();
  FObjects := nil;
end;

destructor TclMultipleTypeMapObject.Destroy;
begin
  Objects := nil;
  inherited Destroy();
end;

procedure TclMultipleTypeMapObject.SetObjects(const Value: TObjectDictionary<string, TclTestBaseObject>);
begin
  FObjects.Free();
  FObjects := Value;
end;

{ TclListObject }

constructor TclListObject.Create;
begin
  inherited Create();
  FObjects := nil;
end;

destructor TclListObject.Destroy;
begin
  Objects := nil;
  inherited Destroy();
end;

procedure TclListObject.SetObjects(const Value: TObjectList<TclListObjectItem>);
begin
  FObjects.Free();
  FObjects := Value;
end;

initialization
  TestFramework.RegisterTest(TclJsonSerializerTests.Suite);

end.
