Red/System [
	Title:   "Time! datatype runtime functions"
	Author:  "Nenad Rakocevic"
	File: 	 %time.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2016-2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/red-system/runtime/BSL-License.txt
	}
]

time: context [
	verbose: 0

	h-factor: 3600.0
	m-factor: 60.0

	#define GET_HOURS(time)   (floor time / h-factor)
	#define GET_MINUTES(time) (floor (fmod time 3600.0) / 60.0)
	#define GET_SECONDS(time) (fmod time 60.0)

	throw-error: func [spec [red-value!]][
		fire [TO_ERROR(script bad-to-arg) datatype/push TYPE_TIME spec]
	]

	get-hours: func [tm [float!] return: [integer!]][
		tm: tm / h-factor
		tm: either tm < 0.0 [ceil tm][floor tm]
		as-integer tm
	]

	get-minutes: func [tm [float!] return: [integer!]][
		if tm < 0.0 [tm: 0.0 - tm]
		as-integer floor (fmod tm 3600.0) / 60.0
	]

	push-field: func [
		tm		[red-time!]
		field	[integer!]
		return: [red-value!]
		/local
			t [float!]
	][
		t: tm/time
		as red-value! switch field [
			1 [integer/push time/get-hours t]
			2 [integer/push time/get-minutes t]
			3 [float/push GET_SECONDS(t)]
			default [assert false]
		]
	]
	
	make-in: func [
		parent	[red-block!]
		high	[integer!]
		low		[integer!]
		return: [red-time!]
		/local
			cell [cell!]
	][
		#if debug? = yes [if verbose > 0 [print-line "time/make-in"]]

		cell: ALLOC_TAIL(parent)
		cell/header: TYPE_TIME
		cell/data2: low
		cell/data3: high
		as red-time! cell
	]
	
	make-at: func [
		time	[float!]								;-- in nanoseconds
		cell	[red-value!]
		return: [red-time!]
		/local
			t [red-time!]
	][
		t: as red-time! cell
		set-type cell TYPE_TIME
		t/time: time
		t
	]
	
	push: func [
		time	[float!]								;-- in nanoseconds
		return: [red-time!]
	][
		#if debug? = yes [if verbose > 0 [print-line "time/push"]]
		
		make-at time stack/push*
	]
	
	serialize: func [
		time 	[float!]
		buffer	[red-string!]
		part 	[integer!]
		return: [integer!]
		/local
			formed [c-string!]
			len	   [integer!]
	][
		if time < 0.0 [
			string/append-char GET_BUFFER(buffer) as-integer #"-"
			time: float/abs time
		]

		formed: integer/form-signed as-integer GET_HOURS(time)
		string/concatenate-literal buffer formed
		part: part - length? formed						;@@ optimize by removing length?

		string/append-char GET_BUFFER(buffer) as-integer #":"

		formed: integer/form-signed as-integer GET_MINUTES(time)
		len: length? formed								;@@ optimize by removing length?
		if len = 1 [
			string/append-char GET_BUFFER(buffer) as-integer #"0"
			len: 2
		]
		string/concatenate-literal buffer formed
		part: part - 1 - len

		string/append-char GET_BUFFER(buffer) as-integer #":"

		time: GET_SECONDS(time)
		formed: either time < 1E-6 ["00"][float/form-float time float/FORM_TIME]
		len: length? formed								;@@ optimize by removing length?
		if any [len = 1 formed/2 = #"."][
			string/append-char GET_BUFFER(buffer) as-integer #"0"
			len: len + 1
		]
		string/concatenate-literal buffer formed
		part - 1 - len
	]
	
	;-- Actions --
	
	;make: :to

	to: func [
		proto 	[red-value!]							;-- overwrite this slot with result
		spec	[red-value!]
		type	[integer!]
		return: [red-value!]
		/local
			tm	 [red-time!]
			int  [red-integer!]
			fl	 [red-float!]
			str	 [red-string!]
			blk	 [red-block!]
			len	 [integer!]
			i	 [integer!]
			t	 [float!]
			val  [red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "time/to"]]
		
		if TYPE_OF(spec) = TYPE_TIME [return spec]
		
		tm: as red-time! proto
		tm/header: TYPE_TIME
		
		switch TYPE_OF(spec) [
			TYPE_INTEGER [
				int: as red-integer! spec
				tm/time: as-float int/value
			]
			TYPE_FLOAT
			TYPE_PERCENT [
				fl: as red-float! spec
				tm/time: fl/value
			]
			TYPE_ANY_LIST [
				blk: as red-block! spec
				len: block/rs-length? blk
				if len > 3 [throw-error spec]
				int: as red-integer! block/rs-head blk
				fl: null
				t: 0.0
				i: 1
				loop len [
					either all [i = 3 TYPE_OF(int) = TYPE_FLOAT][
						fl: as red-float! int 
					][
						if TYPE_OF(int) <> TYPE_INTEGER [throw-error spec]
					]
					t: switch i [
						1 [t + ((as-float int/value) * 3600.0)]
						2 [t + ((as-float int/value) * 60.0)]
						3 [either fl = null [t +  as-float int/value][t + fl/value]]
					]
					int: int + 1
					i: i + 1
				]
				tm/time: t
			]
			TYPE_ANY_STRING [
				i: 0
				val: as red-value! :i
				copy-cell spec val					;-- save spec, load-value will change it
				proto: load-value as red-string! spec
				if TYPE_OF(proto) <> TYPE_TIME [throw-error val]
			]
			default [throw-error spec]
		]
		proto
	]
	
	form: func [
		t		[red-time!]
		buffer	[red-string!]
		arg		[red-value!]
		part 	[integer!]
		return: [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "time/form"]]

		serialize t/time buffer part
	]
	
	mold: func [
		t		[red-time!]
		buffer	[red-string!]
		only?	[logic!]
		all?	[logic!]
		flat?	[logic!]
		arg		[red-value!]
		part 	[integer!]
		indent	[integer!]
		return: [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "time/mold"]]
		
		serialize t/time buffer part
	]
	
	eval-path: func [
		t		[red-time!]								;-- implicit type casting
		element	[red-value!]
		value	[red-value!]
		path	[red-value!]
		case?	[logic!]
		get?	[logic!]
		tail?	[logic!]
		return:	[red-value!]
		/local
			word   [red-word!]
			int	   [red-integer!]
			fl	   [red-float!]
			field  [integer!]
			sym	   [integer!]
			time   [float!]
			fval   [float!]
			error? [logic!]
	][
		time: t/time
		error?: no

		switch TYPE_OF(element) [
			TYPE_INTEGER [
				int: as red-integer! element
				field: int/value
				if any [field <= 0 field > 3][error?: yes]
			]
			TYPE_WORD [
				word: as red-word! element
				sym: symbol/resolve word/symbol
				case [
					sym = words/hour   [field: 1]
					sym = words/minute [field: 2]
					sym = words/second [field: 3]
					true 			   [error?: yes]
				]
			]
			default [error?: yes]
		]
		if error? [fire [TO_ERROR(script invalid-path) path element]]
		
		either value <> null [
			switch field [
				1 [
					if TYPE_OF(value) <> TYPE_INTEGER [fire [TO_ERROR(script invalid-arg) value]]
					int: as red-integer! value
					t/time: time - (GET_HOURS(time) - (as-float int/value) * h-factor)
				]
				2 [
					if TYPE_OF(value) <> TYPE_INTEGER [fire [TO_ERROR(script invalid-arg) value]]
					int: as red-integer! value
					t/time: time - (GET_MINUTES(time) - (as-float int/value) * m-factor)
				]
				3 [
					switch TYPE_OF(value) [
						TYPE_INTEGER [
							int: as red-integer! value
							fval: as-float int/value
						]
						TYPE_FLOAT [
							fl: as red-float! value
							fval: fl/value
						]
						default [fire [TO_ERROR(script invalid-arg) value]]
					]
					t/time: time - (GET_SECONDS(time) - fval)
				]
				default [assert false]
			]
			object/check-owner as red-value! t
			value
		][
			value: push-field t field
			stack/pop 1									;-- avoids moving stack up
			value
		]
	]

	add: func [
		return:	[red-value!]
		/local
			left	[red-time!]
			right	[red-time!]
			val		[float!]
	][
		#if debug? = yes [if verbose > 0 [print-line "time/add"]]
		right: as red-time! stack/arguments + 1
		either TYPE_OF(right) = TYPE_DATE [
			left: right - 1								;-- swap them!
			val: left/time
			copy-cell as red-value! right as red-value! left
			right/header: TYPE_TIME
			right/time: val
			as red-value! date/do-math OP_ADD
		][
			as red-value! float/do-math OP_ADD
		]
	]

	subtract: func [
		return:	[red-value!]
		/local
			slot [red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "time/subtract"]]
		slot: stack/arguments + 1
		if TYPE_OF(slot) = TYPE_DATE [
			fire [TO_ERROR(script not-related) words/_subtract datatype/push TYPE_TIME]
		]
		as red-value! float/do-math OP_SUB
	]

	divide: func [
		return: [red-value!]
		/local
			slot  [red-value!]
			time? [logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "time/divide"]]
		slot: stack/arguments + 1
		time?: TYPE_OF(slot) = TYPE_TIME
		slot: as red-value! float/do-math OP_DIV
		if time? [slot/header: TYPE_FLOAT]
		slot
	]
	
	multiply: func [
		return:	[red-value!]
		/local
			slot [red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "time/multiply"]]
		slot: stack/arguments + 1
		if TYPE_OF(slot) = TYPE_TIME [
			fire [TO_ERROR(script not-related) words/_multiply datatype/push TYPE_TIME]
		]
		as red-value! float/do-math OP_MUL
	]
	
	even?: func [
		tm		[red-time!]
		return: [logic!]
		/local
			t [float!]
	][
		t: tm/time
		either t >= 0.0 [t: t + 1E-6][t: t - 1E-6]		;@@ 1E-6 is a temporary, empirical workaround
		not as-logic (as integer! GET_SECONDS(t)) and 1
	]

	odd?: func [
		tm		[red-time!]
		return: [logic!]
		/local
			t [float!]
	][
		t: tm/time
		either t >= 0.0 [t: t + 1E-6][t: t - 1E-6]		;@@ 1E-6 is a temporary, empirical workaround
		as-logic (as integer! GET_SECONDS(t)) and 1
	]

	round: func [
		tm			[red-time!]
		scale		[red-float!]
		_even?		[logic!]
		down?		[logic!]
		half-down?	[logic!]
		floor?		[logic!]
		ceil?		[logic!]
		half-ceil?	[logic!]
		return:		[red-value!]
		/local
			type	[integer!]
			int		[red-integer!]
			val		[float!]
			ret		[red-float!]
	][
		if TYPE_OF(scale) = TYPE_MONEY [
			fire [TO_ERROR(script not-related) stack/get-call datatype/push TYPE_MONEY]
		]
	
		float/round as red-value! tm scale _even? down? half-down? floor? ceil? half-ceil?
		ret: as red-float! tm
		if ret/header = TYPE_INTEGER [
			int: as red-integer! ret
			val: as float! int/value
			ret/value: val
		]
		ret/header: TYPE_TIME
		as red-value! ret
	]
	
	pick: func [
		tm		[red-time!]
		index	[integer!]
		boxed	[red-value!]
		return:	[red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "time/pick"]]

		if any [index < 1 index > 3][fire [TO_ERROR(script out-of-range) boxed]]
		push-field tm index
	]

	init: does [
		datatype/register [
			TYPE_TIME
			TYPE_FLOAT
			"time!"
			;-- General actions --
			:to				;make
			INHERIT_ACTION	;random
			null			;reflect
			:to
			:form
			:mold
			:eval-path
			null			;set-path
			INHERIT_ACTION	;compare
			;-- Scalar actions --
			INHERIT_ACTION	;absolute
			:add
			:divide
			:multiply
			INHERIT_ACTION	;negate
			null			;power
			INHERIT_ACTION	;remainder
			:round
			:subtract
			:even?
			:odd?
			;-- Bitwise actions --
			null			;and~
			null			;complement
			null			;or~
			null			;xor~
			;-- Series actions --
			null			;append
			null			;at
			null			;back
			null			;change
			null			;clear
			null			;copy
			null			;find
			null			;head
			null			;head?
			null			;index?
			null			;insert
			null			;length?
			null			;move
			null			;next
			:pick
			null			;poke
			null			;put
			null			;remove
			null			;reverse
			null			;select
			null			;sort
			null			;skip
			null			;swap
			null			;tail
			null			;tail?
			null			;take
			null			;trim
			;-- I/O actions --
			null			;create
			null			;close
			null			;delete
			null			;modify
			null			;open
			null			;open?
			null			;query
			null			;read
			null			;rename
			null			;update
			null			;write
		]
	]
]
