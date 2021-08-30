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

unit clJsonSerializerBase;

interface

uses
  Classes, SysUtils, Rtti, TypInfo;

type
  EclJsonSerializerError = class(Exception)
  end;

  TclJsonPropertyAttribute = class (TCustomAttribute)
  strict private
    FName: string;
  public
    constructor Create(const AName: string);
    property Name: string read FName;
  end;

  TclJsonStringAttribute = class(TclJsonPropertyAttribute);

  TclJsonRequiredAttribute = class(TCustomAttribute);

  TclJsonTypeNameMapAttribute = class(TCustomAttribute)
  strict private
    FPropertyName: string;
    FTypeName: string;
    FTypeClassName: string;
  public
    constructor Create(const APropertyName, ATypeName, ATypeClassName: string);
    property PropertyName: string read FPropertyName;
    property TypeName: string read FTypeName;
    property TypeClassName: string read FTypeClassName;
  end;

  TclJsonSerializerBase = class abstract
  public
    function JsonToObject(AType: TClass; const AJson: string): TObject; overload; virtual; abstract;
    function JsonToObject(AObject: TObject; const AJson: string): TObject; overload; virtual; abstract;
    function ObjectToJson(AObject: TObject): string; virtual; abstract;
  end;

implementation

{ TclJsonPropertyAttribute }

constructor TclJsonPropertyAttribute.Create(const AName: string);
begin
  inherited Create();
  FName := AName;
end;

{ TclJsonTypeNameMapAttribute }

constructor TclJsonTypeNameMapAttribute.Create(const APropertyName, ATypeName, ATypeClassName: string);
begin
  inherited Create();

  FPropertyName := APropertyName;
  FTypeName := ATypeName;
  FTypeClassName := ATypeClassName;
end;

end.
