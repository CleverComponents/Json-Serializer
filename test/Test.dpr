program Test;

uses
  Vcl.Forms,
  TestFrameWork,
  GUITestRunner,
  clJsonSerializerBase in '..\json\clJsonSerializerBase.pas',
  clJsonSerializerTests in 'clJsonSerializerTests.pas',
  clJsonSerializer in '..\json\clJsonSerializer.pas',
  clJsonParser in '..\json\clJsonParser.pas';

{$R *.res}

begin
  Application.Initialize;
  GUITestRunner.RunRegisteredTests;
end.
