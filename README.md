# JSON object serializer for Delphi

<img align="left" src="https://www.clevercomponents.com/images/Json-serializer-3.jpg" />

TclJsonSerializer utilizes the RTTI library and custom Delphi attributes for linking user-defined Delphi objects and properties with the corresponding JSON data parts. The updated JSON serializer correctly invokes constructors of serialized objects by requesting RTTI information for object constructors and calling it with the Invoke method.

You can serialize and deserialize arrays and unions of objects of different types, deserialize inherited objects, serialize empty strings and many more. The article includes both the source code of the Json Serializer classes (TclJsonSerializer) and unit-test code that demonstrates how to serialize and deserizlise differrent data types, inlcuding Delphi strings, integers, objects and arrays.

[Read the article](https://www.clevercomponents.com/articles/article040/)