Red [
	Title:	 "Red GUI Console"
	Author:	 "Qingtian Xie"
	File:	 %gui-console.red
	Tabs:	 4
	Icon:	 %app.ico
	Version: 0.0.1
	Needs:	 View
	Config:	 [gui-console?: yes red-help?: yes]
	Rights:  "Copyright (C) 2014-2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#if config/debug? [
	debug-print: routine [
		"Output debug info to CLI console only"
		arg [any-type!] /local blk [red-block!]
	][
		#if sub-system = 'console [
			if TYPE_OF(arg) = TYPE_BLOCK [
				block/rs-clear natives/buffer-blk
				stack/push as red-value! natives/buffer-blk
				natives/reduce* no 1
				blk: as red-block! arg
				blk/head: 0						;-- head changed by reduce/into
			]
			actions/form* -1
			dyn-print/red-print-cli as red-string! stack/arguments yes
		]
	]
]

#include %../help.red
#include %../engine.red
#include %../auto-complete.red
#include %highlight.red
#include %tips.red

gui-console-ctx: context [
	cfg-dir:	none
	cfg-path:	none
	cfg:		none
	font:		make font! [name: system/view/fonts/fixed size: 11 color: 0.0.0]
	caret-clr:	0.0.0.1
	scroller:	make scroller! []

	console:	make face! [
		type: 'rich-text color: 0.0.128 offset: 0x0 size: 200x200
		flags:   [scrollable all-over]
		options: [cursor: I-beam]
		menu: [
			#either config/OS = 'macOS [
				"Copy^-Command+C"	copy
				"Paste^-Command+V"	paste
			][
				"Copy^-Ctrl+C"		copy
				"Paste^-Shift+Ins"	paste
			]
			---
			"Select All"		select-all
		]
		actors: object [
			on-time: func [face [object!] event [event!]][
				if caret/enabled? [caret/rate: 2]
				terminal/on-time
				'done
			]
			on-drawing: func [face [object!] event [event!]][
				terminal/paint
			]
			on-scroll: func [face [object!] event [event!]][
				terminal/scroll event
			]
			on-wheel: func [face [object!] event [event!]][
				either event/ctrl? [
					terminal/zoom event
				][
					terminal/scroll event
				]
			]
			on-key: func [face [object!] event [event!]][
				terminal/press-key event
			]
			on-ime: func [face [object!] event [event!]][
				terminal/process-ime-input event
			]
			on-down: func [face [object!] event [event!]][
				terminal/mouse-down event
			]
			on-up: func [face [object!] event [event!]][
				terminal/mouse-up event
			]
			on-over: func [face [object!] event [event!]][
				terminal/mouse-move event/offset
			]
			on-menu: func [face [object!] event [event!]][
				switch event/picked [
					copy		[terminal/copy-selection]
					paste		[terminal/paste]
					select-all	[terminal/select-all]
				]
				'done
			]
		]

		tabs: none line-spacing: 'default handles: none	;-- extra fields

		init: func [/local box][
			terminal/windows: system/view/screens/1/pane
			box: terminal/box
			box/data: make block! 200
			scroller: get-scroller self 'horizontal
			scroller/visible?: no						;-- hide horizontal bar
			scroller: get-scroller self 'vertical
			scroller/position: 1
			scroller/max-size: 2
		]
	]

	caret: make face! [
		type: 'base color: caret-clr offset: 0x0 size: 1x17 rate: 2 enabled?: no
		options: compose [caret (console) cursor: I-beam accelerated: yes]
		actors: object [
			on-time: func [face [object!] event [event!]][
				face/color: either face/color = caret-clr [255.255.255.254][caret-clr]
				'done
			]
		]
	]
	tips: make tips! [visible?: no]

	terminal: #include %core.red

	#include %settings.red

	show-caret: func [][unless caret/enabled? [caret/enabled?: yes]]

	setup-faces: does [
		;console/pane: reduce [caret]
		append win/pane reduce [console caret tips]
		win/menu: [
			"File" [
				"Run..."			run-file
				---
				"Quit"				quit
			]
			"Options" [
				"Choose Font..."	choose-font
				"Settings..."		settings
			]
			;"Plugins" [
			;	"Add..."			add-plugin
			;]
			"Help" [
				"About"				about-msg
			]
		]
		win/actors: object [
			on-menu: func [face [object!] event [event!] /local ft f][
				switch event/picked [
					about-msg		[display-about]
					quit			[self/on-close face event]
					run-file		[if f: request-file [terminal/run-file f]]
					choose-font		[
						if ft: request-font/font/mono font [
							font: ft
							console/font: font
							terminal/zoom font
						]
					]
					settings		[show-cfg-dialog]
				]
			]
			on-close: func [face [object!] event [event!]][
				save-cfg
				system/view/platform/exit-event-loop
				clear head system/view/screens/1/pane
				quit
			]
			on-resizing: function [face [object!] event [event!]][
				new-sz: event/offset
				console/size: new-sz
				terminal/resize new-sz
				terminal/adjust-console-size new-sz
				unless system/view/auto-sync? [show face]
			]
			on-focus: func [face [object!] event [event!]][
				caret/color: caret-clr
				unless caret/enabled? [caret/enabled?: yes]
				caret/rate: 2
				terminal/refresh
			]
			on-unfocus: func [face [object!] event [event!]][
				if caret/enabled? [caret/enabled?: no]
				caret/rate: none
			]
		]
		tips/parent: win
	]

	win: layout/tight [						;-- main window
		title "Red Console"
		size  200x200
	]

	add-gui-print: routine [][
		gui-console-buffer: ALLOC_TAIL(root)
		gui-console-buffer/header: TYPE_UNSET
		dyn-print/add as int-ptr! :red-print-gui #either debug? = yes [null][
			as int-ptr! :rs-print-gui
		]
	]

	launch: func [/local svs][
		setup-faces
		win/visible?: no					;-- hide it first to avoid flicker

		view/flags/no-wait win [resize]		;-- create window instance
		console/init
		load-cfg
		if empty? system/script/args [win/visible?: yes]

		svs: system/view/screens/1
		svs/pane: next svs/pane				;-- proctect itself from unview/all

		add-gui-print
		system/console/launch
	]
]

_save-cfg: function [][
	gui-console-ctx/save-cfg
]

ask: function [
	"Prompt the user for input"
	question [string!]
	/hide
	return:  [string!]
][
	if all [
		gui-console-ctx/console/state
		not gui-console-ctx/win/visible?
	][
		gui-console-ctx/win/visible?: yes
	]

	gui-console-ctx/show-caret

	line: make string! 8
	line: insert line question

	vt: gui-console-ctx/terminal
	vt/line: line
	vt/pos: 0
	vt/add-line head line
	vt/line-pos: length? vt/lines
	vt/ask?: yes
	vt/reset-top/force
	vt/clear-stack
	vt/set-flag hide
	either vt/paste/resume [
		vt/do-ask-loop/no-wait
	][
		system/view/platform/redraw gui-console-ctx/console
		system/view/auto-sync?: yes
		do-events
	]
	vt/ask?: no
	gui-console-ctx/caret/enabled?: no
	unless gui-console-ctx/console/state [line: "quit"]
	line
]

input: function ["Wait for console user input" return: [string!]][ask ""]

#system [
	gui-console-buffer: as red-value! 0

	red-print-gui: func [
		str		[red-string!]
		lf?		[logic!]
	][
		#call [gui-console-ctx/terminal/vprint str lf?]
	]

	rs-print-gui: func [
		cstr	[c-string!]
		size	[integer!]
		lf?		[logic!]
		/local
			str [red-string!]
	][
		str: as red-string! gui-console-buffer
		if negative? size [size: length? cstr]
		either TYPE_OF(str) = TYPE_STRING [
			string/rs-reset str
			unicode/load-utf8-buffer cstr size GET_BUFFER(str) null yes
		][
			str/header: TYPE_UNSET
			str/node: unicode/load-utf8-buffer cstr size null null yes
			str/header: TYPE_STRING
			str/head: 0
			str/cache: null
		]
		red-print-gui str lf?
	]
]

gui-console-ctx/launch