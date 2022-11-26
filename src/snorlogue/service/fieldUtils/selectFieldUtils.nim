import std/[options, algorithm, sugar, sequtils]
import ./fieldTypes
import norm/model

when defined(postgres):
  import ../postgresService
elif defined(sqlite):
  import ../sqliteService
else:
  {.error: "Snorlogue requires you to specify which database type you use via a defined flag. Please specify either '-d:sqlite' or '-d:postgres'".}


func toIntSelectFormField(value: Option[int64], intOptions: seq[IntOption], isRequired: bool, fieldName: string): FormField =
  ## Converts a model field with value and all its options into an Int-Select-Field
  var options = intOptions
  options.sort((opt1, opt2: IntOption) => cmp(opt1.name, opt2.name))

  result = FormField(name: fieldName, isRequired: isRequired, kind: FormFieldKind.INTSELECT, intSeqVal: value, intOptions: options)

func toStringSelectFormField(value: Option[string], stringOptions: seq[StringOption], isRequired: bool, fieldName: string): FormField =
  ## Converts a model field with value and all its options into a String-Select-Field
  var options = stringOptions
  options.sort((opt1, opt2: StringOption) => cmp(opt1.name, opt2.name))

  result = FormField(name: fieldName, isRequired: isRequired, kind: FormFieldKind.STRSELECT, strSeqVal: value, strOptions: options)



func toSelectFormField*[T: enum](value: Option[T], fieldName: string, isRequired: bool): FormField =
  ## Converts an optional or mandatory enum field on a Model into an Int-Select-field
  var enumOptions: seq[IntOption] = @[]
  for enumValue in T:
    enumOptions.add(IntOption(name: $enumValue, value: enumValue.int))

  toIntSelectFormField(value.map(val => val.int64), enumOptions, isRequired, fieldName)

func toSelectFormField*[T: enum](value: T, fieldName: string, isRequired: bool): FormField =
  ## Helper proc to convert mandatory Enum fields on a Model into an Int-Select-Field
  toSelectFormField(some value, fieldName, isRequired)

proc toSelectFormField*[T: Model](value: Option[int64], fieldName: static string, isRequired: bool, foreignKeyModelType: typedesc[T]): FormField =
  ## Converts an optional or mandatory Foreign Key field on a Model into an Int-Select-Field
  let fkEntries = listAll(T)
  let fkOptions = fkEntries.mapIt(IntOption(name: $it, value: it.id))

  toIntSelectFormField(value, fkOptions, isRequired, fieldName)

proc toSelectFormField*[T: Model](value: int64, fieldName: static string, isRequired: bool, foreignKeyModelType: typedesc[T]): FormField =
  ## Helper proc to convert mandatory Foreign Key fields on a Model into an Int-Select-Field
  toSelectFormField(some value, fieldName, isRequired, T)