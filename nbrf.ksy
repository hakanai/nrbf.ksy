meta:
  id: nrbf
  endian: le
  application: .NET
  imports:
    - vlq_base128_le

doc: |
  .NET binary serialisation format (BinaryFormatter)

seq:
  - id: records
    type: record
    repeat: expr
    repeat-expr: 4


types:

  # 2 Structures
  
  # 2.1 Common Definitions
  
  # 2.1.1 Common Data Types

  # 2.1.1.1 Char
  # TODO: UTF-8 variable encoded bytes
  
  # 2.1.1.2 Double
  # We will use f8
  
  # 2.1.1.3 Single
  # We will use f4
  
  # 2.1.1.4 TimeSpan
  time_span:
    seq:
      - id: value
        type: s8

  # 2.1.1.5 DateTime
  date_time:
    seq:
      - id: ticks
        type: b62
      - id: kind # here be dragons
        type: b2
    -webide-representation: 'ticks={ticks} kind={kind}'

  # 2.1.1.6 LengthPrefixedString
  length_prefixed_string:
    seq:
      - id: length
        type: vlq_base128_le
      - id: chars
        type: str
        encoding: 'UTF-8'
        size: length.value
    -webide-representation: '{chars}'

  # 2.1.1.7 Decimal
  decimal:
    seq:
      - id: value
        type: length_prefixed_string
    -webide-representation: '{value}'

  # 2.1.1.8 ClassTypeInfo
  class_type_info:
    seq:
      - id: type_name
        type: length_prefixed_string
      - id: library_id
        type: s4

  # 2.3.1.1 ClassInfo
  class_info:
    seq:
      - id: object_id
        type: s4
      - id: name
        type: length_prefixed_string
      - id: member_count
        type: s4
      - id: member_names
        type: length_prefixed_string
        repeat: expr
        repeat-expr: member_count
    -webide-representation: 'object_id={object_id}, name={name}'

  # 2.3.1.2 MemberTypeInfo
  member_type_info:
    seq:
      - id: binary_type_enums
        type: u1
        enum: binary_type_enumeration
        repeat: expr
        repeat-expr: _parent.class_info.member_count
      - id: additional_infos
        type: member_type_info_additional_info(_index)
        repeat: expr
        repeat-expr: _parent.class_info.member_count
  member_type_info_additional_info:
    params:
      - id: i
        type: u4
    seq:
      - id: primitive_type
        type: u1
        enum: primitive_type_enumeration
        if: |
          binary_type_enum == binary_type_enumeration::primitive or
          binary_type_enum == binary_type_enumeration::primitive_array
      - id: class_name
        type: length_prefixed_string
        if: binary_type_enum == binary_type_enumeration::system_class
      - id: class_type_info
        type: class_type_info
        if: binary_type_enum == binary_type_enumeration::class
    instances:
      binary_type_enum:
        value: _parent.binary_type_enums[i]
  
  record:
    seq:
      - id: record_type_enum
        type: u1
        enum: record_type_enumeration
      - id: payload
        type:
          switch-on: record_type_enum
          cases:
            'record_type_enumeration::serialized_stream_header': serialization_header_record
            'record_type_enumeration::binary_library': binary_library
            'record_type_enumeration::class_with_members_and_types': class_with_members_and_types
    -webide-representation: 'type={recordTypeEnum}, payload={payload}'

  # 0x0 (0)
  serialization_header_record:
    seq:
      - id: top_id
        type: u4
      - id: header_id
        type: u4
      - id: major_version
        type: u4
      - id: minor_version
        type: u4
    -webide-representation: 'top_id={top_id} header_id={header_id} version={major_version:dec}.{minor_version:dec}'

  # 2.3.2.1 ClassWithMembersAndTypes
  class_with_members_and_types:
    seq:
      - id: class_info
        type: class_info
      - id: member_type_info
        type: member_type_info
      - id: library_id
        type: s4
    -webide-representation: 'class_info={class_info} library_id={library_id}'

  # 2.3.2.2 ClassWithMembers
  class_with_members:
    seq:
      - id: class_info
        type: class_info
      - id: library_id
        type: s4
    -webide-representation: 'class_info={class_info} library_id={library_id}'

  # 2.3.2.3 SystemClassWithMembersAndTypes
  system_class_with_members_and_types:
    seq:
      - id: class_info
        type: class_info
      - id: member_type_info
        type: member_type_info
    -webide-representation: 'class_info={class_info}'

  # 2.3.2.4 SystemClassWithMembers
  system_class_with_members:
    seq:
      - id: class_info
        type: class_info
    -webide-representation: 'class_info={class_info}'

  # 2.3.2.5 ClassWithId
  class_with_id:
    seq:
      - id: object_id
        type: s4
      - id: metadata_id
        type: s4
    -webide-representation: 'object_id={object_id} metadata_id={metadata_id}'
    
  # 0xC (12)
  binary_library:
    seq:
      - id: library_id
        type: u4
      - id: library_name
        type: length_prefixed_string
    -webide-representation: 'id={library_id}, name={library_name}'

enums:

  record_type_enumeration:
    0: serialized_stream_header
    1: class_with_id
    2: system_class_with_members
    3: class_with_members
    4: system_class_with_members_and_types
    5: class_with_members_and_types
    6: binary_object_string
    7: binary_array
    8: member_primitive_typed
    9: member_reference
    10: object_null
    11: message_end
    12: binary_library
    13: object_null_multiple256
    14: object_null_multiple
    15: array_single_primitive
    16: array_single_object
    17: array_single_string
    21: method_call
    22: method_return

  binary_type_enumeration:
    0: primitive
    1: string
    2: object
    3: system_class
    4: class
    5: object_array
    6: string_array
    7: primitive_array

  primitive_type_enumeration:
    1: boolean
    2: byte
    3: char
    4: unused4
    5: decimal
    6: double
    7: int16
    8: int32
    9: int64
    10: sbyte
    11: single
    12: time_span
    13: date_time
    14: uint16
    15: uint32
    16: uint64
    17: 'null'
    18: string

#   message_flags:
#     0x00000001: no_args
#     0x00000002: args_inline
#     0x00000004: args_is_array
#     0x00000008: args_in_array
#     0x00000010: no_context
#     0x00000020: context_inline
#     0x00000040: context_in_array
#     0x00000080: method_signature_in_array
#     0x00000100: properties_in_array
#     0x00000200: no_return_value
#     0x00000400: return_value_void
#     0x00000800: return_value_inline
#     0x00001000: return_value_in_array
#     0x00002000: exception_in_array
#     0x00008000: generic_method


#   compression_format:
#     0x0101: none
#     0x8b1f: something
