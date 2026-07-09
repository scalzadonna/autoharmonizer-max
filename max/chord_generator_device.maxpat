{
	"patcher": {
		"fileversion": 1,
		"appversion": {
			"major": 8,
			"minor": 5,
			"revision": 0,
			"architecture": "x64",
			"modernui": 1
		},
		"classnamespace": "box",
		"rect": [
			80.0,
			80.0,
			1040.0,
			860.0
		],
		"bglocked": 0,
		"openinpresentation": 1,
		"default_fontsize": 12.0,
		"default_fontface": 0,
		"default_fontname": "Arial",
		"gridenabled": 1,
		"gridsize": [
			15.0,
			15.0
		],
		"boxes": [
			{
				"box": {
					"id": "obj-title",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						30.0,
						20.0,
						460.0,
						20.0
					],
					"text": "CHORD GENERATOR   \u00b7   markov \u00b7 rnn \u00b7 lstm",
					"presentation": 1,
					"presentation_rect": [
						20.0,
						10.0,
						480.0,
						20.0
					]
				}
			},
			{
				"box": {
					"id": "obj-hint",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						30.0,
						42.0,
						500.0,
						20.0
					],
					"text": "Pick a chord from the menu, then ping/send. npm install once. Pick model and session below."
				}
			},
			{
				"box": {
					"id": "obj-input-label",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						30.0,
						80.0,
						120.0,
						20.0
					],
					"text": "chord",
					"presentation": 1,
					"presentation_rect": [
						20.0,
						40.0,
						90.0,
						18.0
					]
				}
			},
			{
				"box": {
					"id": "obj-chord-menu",
					"maxclass": "umenu",
					"numinlets": 1,
					"numoutlets": 3,
					"outlettype": [
						"int",
						"",
						""
					],
					"parameter_enable": 0,
					"patching_rect": [
						30.0,
						105.0,
						120.0,
						22.0
					],
					"items": [
						"C:maj7",
						",",
						"G:7",
						",",
						"C:maj",
						",",
						"D:min7",
						",",
						"A:min7",
						",",
						"F:maj7",
						",",
						"E:7",
						",",
						"A:7",
						",",
						"D:7",
						",",
						"B:min7",
						",",
						"G:min7",
						",",
						"A-:7",
						",",
						"F:min7"
					],
					"presentation": 1,
					"presentation_rect": [
						20.0,
						60.0,
						150.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-btn-send",
					"maxclass": "textbutton",
					"numinlets": 1,
					"numoutlets": 3,
					"outlettype": [
						"",
						"",
						""
					],
					"parameter_enable": 0,
					"patching_rect": [
						170.0,
						105.0,
						60.0,
						22.0
					],
					"text": "send",
					"presentation": 1,
					"presentation_rect": [
						20.0,
						150.0,
						52.0,
						24.0
					]
				}
			},
			{
				"box": {
					"id": "obj-btn-ping",
					"maxclass": "textbutton",
					"numinlets": 1,
					"numoutlets": 3,
					"outlettype": [
						"",
						"",
						""
					],
					"parameter_enable": 0,
					"patching_rect": [
						250.0,
						105.0,
						60.0,
						22.0
					],
					"text": "ping",
					"presentation": 1,
					"presentation_rect": [
						76.0,
						150.0,
						46.0,
						24.0
					]
				}
			},
			{
				"box": {
					"id": "obj-btn-reload",
					"maxclass": "textbutton",
					"numinlets": 1,
					"numoutlets": 3,
					"outlettype": [
						"",
						"",
						""
					],
					"parameter_enable": 0,
					"patching_rect": [
						330.0,
						105.0,
						60.0,
						22.0
					],
					"text": "reload",
					"presentation": 1,
					"presentation_rect": [
						126.0,
						150.0,
						56.0,
						24.0
					]
				}
			},
			{
				"box": {
					"id": "obj-btn-npm",
					"maxclass": "textbutton",
					"numinlets": 1,
					"numoutlets": 3,
					"outlettype": [
						"",
						"",
						""
					],
					"parameter_enable": 0,
					"patching_rect": [
						410.0,
						105.0,
						90.0,
						22.0
					],
					"text": "npm install",
					"presentation": 1,
					"presentation_rect": [
						186.0,
						150.0,
						88.0,
						24.0
					]
				}
			},
			{
				"box": {
					"id": "obj-btn-restart",
					"maxclass": "textbutton",
					"numinlets": 1,
					"numoutlets": 3,
					"outlettype": [
						"",
						"",
						""
					],
					"parameter_enable": 0,
					"patching_rect": [
						510.0,
						105.0,
						90.0,
						22.0
					],
					"text": "restart js",
					"presentation": 1,
					"presentation_rect": [
						278.0,
						150.0,
						80.0,
						24.0
					]
				}
			},
			{
				"box": {
					"id": "obj-model-label",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						30.0,
						175.0,
						120.0,
						20.0
					],
					"text": "model",
					"presentation": 1,
					"presentation_rect": [
						186.0,
						40.0,
						90.0,
						18.0
					]
				}
			},
			{
				"box": {
					"id": "obj-model-menu",
					"maxclass": "umenu",
					"numinlets": 1,
					"numoutlets": 3,
					"outlettype": [
						"int",
						"",
						""
					],
					"parameter_enable": 0,
					"patching_rect": [
						30.0,
						200.0,
						120.0,
						22.0
					],
					"items": [
						"markov",
						",",
						"rnn",
						",",
						"lstm"
					],
					"presentation": 1,
					"presentation_rect": [
						186.0,
						60.0,
						110.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-session-label",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						280.0,
						175.0,
						120.0,
						20.0
					],
					"text": "session",
					"presentation": 1,
					"presentation_rect": [
						20.0,
						92.0,
						90.0,
						18.0
					]
				}
			},
			{
				"box": {
					"id": "obj-session-menu",
					"maxclass": "umenu",
					"numinlets": 1,
					"numoutlets": 3,
					"outlettype": [
						"int",
						"",
						""
					],
					"parameter_enable": 0,
					"patching_rect": [
						280.0,
						200.0,
						120.0,
						22.0
					],
					"items": [
						"auto",
						",",
						"stateless",
						",",
						"session"
					],
					"presentation": 1,
					"presentation_rect": [
						20.0,
						112.0,
						110.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-prepend-session",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						420.0,
						200.0,
						105.0,
						22.0
					],
					"text": "prepend session"
				}
			},
			{
				"box": {
					"id": "obj-btn-reset-session",
					"maxclass": "textbutton",
					"numinlets": 1,
					"numoutlets": 3,
					"outlettype": [
						"",
						"",
						""
					],
					"parameter_enable": 0,
					"patching_rect": [
						540.0,
						200.0,
						90.0,
						22.0
					],
					"text": "reset session",
					"presentation": 1,
					"presentation_rect": [
						140.0,
						112.0,
						100.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-msg-reset-session",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						540.0,
						170.0,
						90.0,
						22.0
					],
					"text": "reset_session"
				}
			},
			{
				"box": {
					"id": "obj-session-display-label",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						780.0,
						260.0,
						80.0,
						20.0
					],
					"text": "session",
					"presentation": 1,
					"presentation_rect": [
						400.0,
						100.0,
						90.0,
						18.0
					]
				}
			},
			{
				"box": {
					"id": "obj-session-display",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						780.0,
						285.0,
						120.0,
						22.0
					],
					"text": "set stateless 0",
					"presentation": 1,
					"presentation_rect": [
						470.0,
						100.0,
						270.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-prepend-set-session",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						780.0,
						240.0,
						65.0,
						22.0
					],
					"text": "prepend set"
				}
			},
			{
				"box": {
					"id": "obj-pack-session",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						780.0,
						210.0,
						60.0,
						22.0
					],
					"text": "pack s i"
				}
			},
			{
				"box": {
					"id": "obj-prepend-model",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						170.0,
						200.0,
						95.0,
						22.0
					],
					"text": "prepend model"
				}
			},
			{
				"box": {
					"id": "obj-model-display-label",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						620.0,
						260.0,
						80.0,
						20.0
					],
					"text": "active model",
					"presentation": 1,
					"presentation_rect": [
						400.0,
						70.0,
						90.0,
						18.0
					]
				}
			},
			{
				"box": {
					"id": "obj-model-display",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						620.0,
						285.0,
						120.0,
						22.0
					],
					"text": "set markov",
					"presentation": 1,
					"presentation_rect": [
						470.0,
						70.0,
						270.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-prepend-set-chord",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						30.0,
						135.0,
						65.0,
						22.0
					],
					"text": "prepend set"
				}
			},
			{
				"box": {
					"id": "obj-chord-store",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						105.0,
						135.0,
						80.0,
						22.0
					],
					"text": "C:maj7"
				}
			},
			{
				"box": {
					"id": "obj-prepend-chord",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						30.0,
						165.0,
						90.0,
						22.0
					],
					"text": "prepend chord"
				}
			},
			{
				"box": {
					"id": "obj-msg-npm",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						410.0,
						140.0,
						100.0,
						22.0
					],
					"text": "script npm install"
				}
			},
			{
				"box": {
					"id": "obj-msg-ping",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						250.0,
						140.0,
						35.0,
						22.0
					],
					"text": "ping"
				}
			},
			{
				"box": {
					"id": "obj-msg-reload",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						330.0,
						140.0,
						45.0,
						22.0
					],
					"text": "reload"
				}
			},
			{
				"box": {
					"id": "obj-msg-restart",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						510.0,
						140.0,
						70.0,
						22.0
					],
					"text": "script stop"
				}
			},
			{
				"box": {
					"id": "obj-msg-restart2",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						510.0,
						170.0,
						70.0,
						22.0
					],
					"text": "script start"
				}
			},
			{
				"box": {
					"id": "obj-node",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						250.0,
						210.0,
						150.0,
						22.0
					],
					"text": "node.script markov_osc.js",
					"filename": "markov_osc.js"
				}
			},
			{
				"box": {
					"id": "obj-route",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 8,
					"outlettype": [
						"",
						"",
						"",
						"",
						"",
						"",
						"",
						""
					],
					"patching_rect": [
						450.0,
						210.0,
						160.0,
						22.0
					],
					"text": "route status output error model session notes stop"
				}
			},
			{
				"box": {
					"id": "obj-status-label",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						450.0,
						260.0,
						80.0,
						20.0
					],
					"text": "status",
					"presentation": 1,
					"presentation_rect": [
						400.0,
						40.0,
						90.0,
						18.0
					]
				}
			},
			{
				"box": {
					"id": "obj-status",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						450.0,
						285.0,
						120.0,
						22.0
					],
					"text": "set $1",
					"presentation": 1,
					"presentation_rect": [
						470.0,
						40.0,
						270.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-output-label",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						450.0,
						320.0,
						80.0,
						20.0
					],
					"text": "output",
					"presentation": 1,
					"presentation_rect": [
						400.0,
						138.0,
						90.0,
						18.0
					]
				}
			},
			{
				"box": {
					"id": "obj-output",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						450.0,
						345.0,
						150.0,
						22.0
					],
					"text": "set $1",
					"presentation": 1,
					"presentation_rect": [
						400.0,
						158.0,
						340.0,
						26.0
					]
				}
			},
			{
				"box": {
					"id": "obj-error-label",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						450.0,
						380.0,
						80.0,
						20.0
					],
					"text": "error",
					"presentation": 1,
					"presentation_rect": [
						400.0,
						196.0,
						90.0,
						18.0
					]
				}
			},
			{
				"box": {
					"id": "obj-error",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						450.0,
						405.0,
						220.0,
						22.0
					],
					"text": "set $1",
					"presentation": 1,
					"presentation_rect": [
						400.0,
						216.0,
						340.0,
						26.0
					]
				}
			},
			{
				"box": {
					"id": "obj-outlet",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						620.0,
						345.0,
						60.0,
						22.0
					],
					"text": "out s"
				}
			},
			{
				"box": {
					"id": "obj-print-status",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						580.0,
						285.0,
						70.0,
						22.0
					],
					"text": "print status"
				}
			},
			{
				"box": {
					"id": "obj-print-output",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						620.0,
						375.0,
						55.0,
						22.0
					],
					"text": "print output"
				}
			},
			{
				"box": {
					"id": "obj-print-error",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						450.0,
						440.0,
						45.0,
						22.0
					],
					"text": "print error"
				}
			},
			{
				"box": {
					"id": "obj-loadbang",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						"bang"
					],
					"patching_rect": [
						250.0,
						55.0,
						60.0,
						22.0
					],
					"text": "loadbang"
				}
			},
			{
				"box": {
					"id": "obj-msg-start",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						250.0,
						140.0,
						70.0,
						22.0
					],
					"text": "script start"
				}
			},
			{
				"box": {
					"id": "obj-init-delay",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						"bang"
					],
					"patching_rect": [
						250.0,
						80.0,
						55.0,
						22.0
					],
					"text": "delay 300"
				}
			},
			{
				"box": {
					"id": "obj-ping-delay",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						"bang"
					],
					"patching_rect": [
						330.0,
						170.0,
						55.0,
						22.0
					],
					"text": "delay 200"
				}
			},
			{
				"box": {
					"id": "obj-msg-init",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						330.0,
						140.0,
						35.0,
						22.0
					],
					"text": "init"
				}
			},
			{
				"box": {
					"id": "obj-status-wait",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						580.0,
						255.0,
						55.0,
						22.0
					],
					"text": "waiting"
				}
			},
			{
				"box": {
					"id": "obj-dial-rhythm",
					"maxclass": "live.dial",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"parameter_enable": 1,
					"patching_rect": [
						700.0,
						480.0,
						44.0,
						48.0
					],
					"presentation": 1,
					"presentation_rect": [
						26.0,
						210.0,
						46.0,
						52.0
					],
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_longname": "Rhythm",
							"parameter_shortname": "Rhythm",
							"parameter_type": 0,
							"parameter_mmin": 0.0,
							"parameter_mmax": 1.0,
							"parameter_unitstyle": 1,
							"parameter_modmode": 0,
							"parameter_initial_enable": 1,
							"parameter_initial": [
								0.0
							]
						}
					},
					"varname": "Rhythm"
				}
			},
			{
				"box": {
					"id": "obj-dial-spice",
					"maxclass": "live.dial",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"float"
					],
					"parameter_enable": 1,
					"patching_rect": [
						760.0,
						480.0,
						44.0,
						48.0
					],
					"presentation": 1,
					"presentation_rect": [
						212.0,
						210.0,
						46.0,
						52.0
					],
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_longname": "Spice",
							"parameter_shortname": "Spice",
							"parameter_type": 0,
							"parameter_mmin": 0.0,
							"parameter_mmax": 1.0,
							"parameter_unitstyle": 1,
							"parameter_modmode": 0,
							"parameter_initial_enable": 1,
							"parameter_initial": [
								0.5
							]
						}
					},
					"varname": "Spice"
				}
			},
			{
				"box": {
					"id": "obj-rhythm-label",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						700.0,
						532.0,
						180.0,
						18.0
					],
					"text": "RHYTHM  \u00b7  auto-advance",
					"fontsize": 11.0,
					"presentation": 1,
					"presentation_rect": [
						20.0,
						190.0,
						180.0,
						18.0
					]
				}
			},
			{
				"box": {
					"id": "obj-spice-label",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						760.0,
						556.0,
						190.0,
						18.0
					],
					"text": "SPICE  \u00b7  adventurousness",
					"fontsize": 11.0,
					"presentation": 1,
					"presentation_rect": [
						206.0,
						190.0,
						190.0,
						18.0
					]
				}
			},
			{
				"box": {
					"id": "obj-prepend-spice",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						820.0,
						480.0,
						90.0,
						22.0
					],
					"text": "prepend spice"
				}
			},
			{
				"box": {
					"id": "obj-rhythm-onoff",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						560.0,
						520.0,
						40.0,
						22.0
					],
					"text": "> 0."
				}
			},
			{
				"box": {
					"id": "obj-rhythm-ms",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						610.0,
						520.0,
						190.0,
						22.0
					],
					"text": "expr 2000. - $f1 * 1750."
				}
			},
			{
				"box": {
					"id": "obj-metro",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						"bang"
					],
					"patching_rect": [
						560.0,
						560.0,
						90.0,
						22.0
					],
					"text": "metro 500"
				}
			},
			{
				"box": {
					"id": "obj-loop-store",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						560.0,
						600.0,
						120.0,
						22.0
					],
					"text": ""
				}
			},
			{
				"box": {
					"id": "obj-loop-chord",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						560.0,
						632.0,
						100.0,
						22.0
					],
					"text": "prepend chord"
				}
			},
			{
				"box": {
					"id": "obj-loop-seed",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						700.0,
						600.0,
						90.0,
						22.0
					],
					"text": "prepend set"
				}
			},
			{
				"box": {
					"id": "obj-loop-out",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						810.0,
						600.0,
						90.0,
						22.0
					],
					"text": "prepend set"
				}
			},
			{
				"box": {
					"id": "obj-notes-trig",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						""
					],
					"patching_rect": [
						780.0,
						560,
						40.0,
						22.0
					],
					"text": "t l b"
				}
			},
			{
				"box": {
					"id": "obj-iter",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						780.0,
						590,
						40.0,
						22.0
					],
					"text": "iter"
				}
			},
			{
				"box": {
					"id": "obj-makenote",
					"maxclass": "newobj",
					"numinlets": 3,
					"numoutlets": 2,
					"outlettype": [
						"",
						""
					],
					"patching_rect": [
						780.0,
						620,
						110.0,
						22.0
					],
					"text": "makenote 90 1000"
				}
			},
			{
				"box": {
					"id": "obj-flush",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 2,
					"outlettype": [
						"",
						""
					],
					"patching_rect": [
						780.0,
						650,
						50.0,
						22.0
					],
					"text": "flush"
				}
			},
			{
				"box": {
					"id": "obj-pack",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						780.0,
						680,
						60.0,
						22.0
					],
					"text": "pack 0 0"
				}
			},
			{
				"box": {
					"id": "obj-midiformat",
					"maxclass": "newobj",
					"numinlets": 8,
					"numoutlets": 1,
					"outlettype": [
						"int"
					],
					"patching_rect": [
						780.0,
						710,
						70.0,
						22.0
					],
					"text": "midiformat"
				}
			},
			{
				"box": {
					"id": "obj-midiout",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 0,
					"outlettype": null,
					"patching_rect": [
						780.0,
						740,
						50.0,
						22.0
					],
					"text": "midiout"
				}
			},
			{
				"box": {
					"id": "obj-vel",
					"maxclass": "number",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"bang"
					],
					"patching_rect": [
						910.0,
						590,
						50.0,
						22.0
					],
					"presentation": 1,
					"presentation_rect": [
						426.0,
						288.0,
						48.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-dur",
					"maxclass": "number",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						"bang"
					],
					"patching_rect": [
						970.0,
						590,
						60.0,
						22.0
					],
					"presentation": 1,
					"presentation_rect": [
						512.0,
						288.0,
						58.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-load-vel",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						910.0,
						560,
						80.0,
						20.0
					],
					"text": "loadmess 90"
				}
			},
			{
				"box": {
					"id": "obj-load-dur",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						1000.0,
						560,
						90.0,
						20.0
					],
					"text": "loadmess 1000"
				}
			},
			{
				"box": {
					"id": "obj-btn-panic",
					"maxclass": "textbutton",
					"numinlets": 1,
					"numoutlets": 3,
					"outlettype": [
						"",
						"",
						""
					],
					"parameter_enable": 0,
					"patching_rect": [
						900.0,
						650,
						60.0,
						22.0
					],
					"text": "panic",
					"presentation": 1,
					"presentation_rect": [
						262.0,
						288.0,
						60.0,
						24.0
					]
				}
			},
			{
				"box": {
					"id": "obj-panic-tb",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						"bang"
					],
					"patching_rect": [
						900.0,
						680,
						30.0,
						22.0
					],
					"text": "t b"
				}
			},
			{
				"box": {
					"id": "obj-midiin",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						"int"
					],
					"patching_rect": [
						560.0,
						560,
						50.0,
						22.0
					],
					"text": "midiin"
				}
			},
			{
				"box": {
					"id": "obj-midiparse",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 7,
					"outlettype": [
						"",
						"",
						"",
						"",
						"",
						"",
						""
					],
					"patching_rect": [
						560.0,
						590,
						70.0,
						22.0
					],
					"text": "midiparse"
				}
			},
			{
				"box": {
					"id": "obj-unpack",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 2,
					"outlettype": [
						"",
						""
					],
					"patching_rect": [
						560.0,
						620,
						70.0,
						22.0
					],
					"text": "unpack 0 0"
				}
			},
			{
				"box": {
					"id": "obj-stripnote",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 2,
					"outlettype": [
						"",
						""
					],
					"patching_rect": [
						560.0,
						650,
						60.0,
						22.0
					],
					"text": "stripnote"
				}
			},
			{
				"box": {
					"id": "obj-midi-gate",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						560.0,
						680,
						50.0,
						22.0
					],
					"text": "gate"
				}
			},
			{
				"box": {
					"id": "obj-prepend-notein",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						560.0,
						710,
						100.0,
						22.0
					],
					"text": "prepend notein"
				}
			},
			{
				"box": {
					"id": "obj-midi-toggle",
					"maxclass": "toggle",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						"int"
					],
					"patching_rect": [
						680.0,
						650,
						24.0,
						24.0
					],
					"presentation": 1,
					"presentation_rect": [
						20.0,
						286.0,
						22.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-load-midi",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						680.0,
						620,
						80.0,
						20.0
					],
					"text": "loadmess 1"
				}
			},
			{
				"box": {
					"id": "obj-midi-strip-label",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						560.0,
						534,
						200.0,
						18.0
					],
					"text": "MIDI OUT \u2192 instrument",
					"fontsize": 11.0,
					"presentation": 1,
					"presentation_rect": [
						400.0,
						270.0,
						190.0,
						18.0
					]
				}
			},
			{
				"box": {
					"id": "obj-vel-label",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						910.0,
						540,
						30.0,
						16.0
					],
					"text": "vel",
					"fontsize": 11.0,
					"presentation": 1,
					"presentation_rect": [
						400.0,
						291.0,
						24.0,
						16.0
					]
				}
			},
			{
				"box": {
					"id": "obj-dur-label",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						960.0,
						540,
						30.0,
						16.0
					],
					"text": "dur",
					"fontsize": 11.0,
					"presentation": 1,
					"presentation_rect": [
						486.0,
						291.0,
						24.0,
						16.0
					]
				}
			},
			{
				"box": {
					"id": "obj-midi-in-label",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						46.0,
						288.0,
						140.0,
						18.0
					],
					"text": "seed from MIDI in",
					"fontsize": 11.0,
					"presentation": 1,
					"presentation_rect": [
						46.0,
						288.0,
						150.0,
						18.0
					]
				}
			},
			{
				"box": {
					"id": "obj-thru-gate",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						660.0,
						740,
						50.0,
						22.0
					],
					"text": "gate"
				}
			},
			{
				"box": {
					"id": "obj-thru-toggle",
					"maxclass": "toggle",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						"int"
					],
					"patching_rect": [
						660.0,
						710,
						24.0,
						24.0
					],
					"presentation": 1,
					"presentation_rect": [
						332.0,
						286.0,
						22.0,
						22.0
					]
				}
			},
			{
				"box": {
					"id": "obj-load-thru",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"outlettype": [
						""
					],
					"patching_rect": [
						660.0,
						680,
						80.0,
						20.0
					],
					"text": "loadmess 1"
				}
			},
			{
				"box": {
					"id": "obj-thru-label",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						720.0,
						710,
						50.0,
						18.0
					],
					"text": "thru",
					"fontsize": 11.0,
					"presentation": 1,
					"presentation_rect": [
						356.0,
						287.0,
						44.0,
						18.0
					]
				}
			}
		],
		"lines": [
			{
				"patchline": {
					"destination": [
						"obj-msg-npm",
						0
					],
					"source": [
						"obj-btn-npm",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-node",
						0
					],
					"source": [
						"obj-msg-npm",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-msg-restart",
						0
					],
					"source": [
						"obj-btn-restart",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-node",
						0
					],
					"source": [
						"obj-msg-restart",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-msg-restart2",
						0
					],
					"source": [
						"obj-msg-restart",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-node",
						0
					],
					"source": [
						"obj-msg-restart2",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-msg-ping",
						0
					],
					"source": [
						"obj-btn-ping",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-node",
						0
					],
					"source": [
						"obj-msg-ping",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-msg-reload",
						0
					],
					"source": [
						"obj-btn-reload",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-node",
						0
					],
					"source": [
						"obj-msg-reload",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-chord-store",
						0
					],
					"source": [
						"obj-btn-send",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-prepend-set-chord",
						0
					],
					"source": [
						"obj-chord-menu",
						1
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-chord-store",
						0
					],
					"source": [
						"obj-prepend-set-chord",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-prepend-chord",
						0
					],
					"source": [
						"obj-chord-store",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-node",
						0
					],
					"source": [
						"obj-prepend-chord",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-route",
						0
					],
					"source": [
						"obj-node",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-status",
						0
					],
					"source": [
						"obj-route",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-print-status",
						0
					],
					"source": [
						"obj-status",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-output",
						0
					],
					"source": [
						"obj-route",
						1
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-outlet",
						0
					],
					"source": [
						"obj-route",
						1
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-print-output",
						0
					],
					"source": [
						"obj-output",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-error",
						0
					],
					"source": [
						"obj-route",
						2
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-print-error",
						0
					],
					"source": [
						"obj-error",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-init-delay",
						0
					],
					"source": [
						"obj-loadbang",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-msg-start",
						0
					],
					"source": [
						"obj-init-delay",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-node",
						0
					],
					"source": [
						"obj-msg-start",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-ping-delay",
						0
					],
					"source": [
						"obj-msg-start",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-msg-init",
						0
					],
					"source": [
						"obj-ping-delay",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-node",
						0
					],
					"source": [
						"obj-msg-init",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-prepend-model",
						0
					],
					"source": [
						"obj-model-menu",
						1
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-node",
						0
					],
					"source": [
						"obj-prepend-model",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-model-display",
						0
					],
					"source": [
						"obj-route",
						3
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-session-display",
						0
					],
					"source": [
						"obj-route",
						4
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-prepend-session",
						0
					],
					"source": [
						"obj-session-menu",
						1
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-node",
						0
					],
					"source": [
						"obj-prepend-session",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-msg-reset-session",
						0
					],
					"source": [
						"obj-btn-reset-session",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-node",
						0
					],
					"source": [
						"obj-msg-reset-session",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-status-wait",
						0
					],
					"source": [
						"obj-loadbang",
						0
					]
				}
			},
			{
				"patchline": {
					"destination": [
						"obj-status",
						0
					],
					"source": [
						"obj-status-wait",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-dial-spice",
						0
					],
					"destination": [
						"obj-prepend-spice",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-prepend-spice",
						0
					],
					"destination": [
						"obj-node",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-dial-rhythm",
						0
					],
					"destination": [
						"obj-rhythm-ms",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-dial-rhythm",
						0
					],
					"destination": [
						"obj-rhythm-onoff",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-rhythm-ms",
						0
					],
					"destination": [
						"obj-metro",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-rhythm-onoff",
						0
					],
					"destination": [
						"obj-metro",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-metro",
						0
					],
					"destination": [
						"obj-loop-store",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-loop-store",
						0
					],
					"destination": [
						"obj-loop-chord",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-loop-chord",
						0
					],
					"destination": [
						"obj-node",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-chord-store",
						0
					],
					"destination": [
						"obj-loop-seed",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-loop-seed",
						0
					],
					"destination": [
						"obj-loop-store",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-route",
						1
					],
					"destination": [
						"obj-loop-out",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-loop-out",
						0
					],
					"destination": [
						"obj-loop-store",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-route",
						5
					],
					"destination": [
						"obj-notes-trig",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-notes-trig",
						1
					],
					"destination": [
						"obj-flush",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-notes-trig",
						0
					],
					"destination": [
						"obj-iter",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-iter",
						0
					],
					"destination": [
						"obj-makenote",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-makenote",
						0
					],
					"destination": [
						"obj-flush",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-makenote",
						1
					],
					"destination": [
						"obj-flush",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-flush",
						0
					],
					"destination": [
						"obj-pack",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-flush",
						1
					],
					"destination": [
						"obj-pack",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-pack",
						0
					],
					"destination": [
						"obj-midiformat",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-midiformat",
						0
					],
					"destination": [
						"obj-midiout",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-route",
						6
					],
					"destination": [
						"obj-flush",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-btn-panic",
						0
					],
					"destination": [
						"obj-panic-tb",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-panic-tb",
						0
					],
					"destination": [
						"obj-flush",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-vel",
						0
					],
					"destination": [
						"obj-makenote",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-dur",
						0
					],
					"destination": [
						"obj-makenote",
						2
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-load-vel",
						0
					],
					"destination": [
						"obj-vel",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-load-dur",
						0
					],
					"destination": [
						"obj-dur",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-midiin",
						0
					],
					"destination": [
						"obj-midiparse",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-midiparse",
						0
					],
					"destination": [
						"obj-unpack",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-unpack",
						0
					],
					"destination": [
						"obj-stripnote",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-unpack",
						1
					],
					"destination": [
						"obj-stripnote",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-midi-toggle",
						0
					],
					"destination": [
						"obj-midi-gate",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-stripnote",
						0
					],
					"destination": [
						"obj-midi-gate",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-midi-gate",
						0
					],
					"destination": [
						"obj-prepend-notein",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-prepend-notein",
						0
					],
					"destination": [
						"obj-node",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-load-midi",
						0
					],
					"destination": [
						"obj-midi-toggle",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-midiin",
						0
					],
					"destination": [
						"obj-thru-gate",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-thru-toggle",
						0
					],
					"destination": [
						"obj-thru-gate",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-thru-gate",
						0
					],
					"destination": [
						"obj-midiout",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"obj-load-thru",
						0
					],
					"destination": [
						"obj-thru-toggle",
						0
					]
				}
			}
		],
		"openrect": [
			0.0,
			0.0,
			760.0,
			330.0
		]
	}
}