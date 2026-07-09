{
	"patcher" : 	{
		"fileversion" : 1,
		"appversion" : 		{
			"major" : 8,
			"minor" : 5,
			"revision" : 0,
			"architecture" : "x64",
			"modernui" : 1
		},
		"classnamespace" : "box",
		"rect" : [ 100.0, 100.0, 900.0, 520.0 ],
		"bglocked" : 0,
		"openinpresentation" : 0,
		"default_fontsize" : 12.0,
		"default_fontface" : 0,
		"default_fontname" : "Arial",
		"gridenabled" : 1,
		"gridsize" : [ 15.0, 15.0 ],
		"boxes" : [ 			{
				"box" : 				{
					"id" : "obj-title",
					"maxclass" : "comment",
					"numinlets" : 1,
					"numoutlets" : 0,
					"patching_rect" : [ 30.0, 20.0, 460.0, 20.0 ],
					"text" : "Chord Generator v3 — Node for Max OSC bridge"
				}

			}
, 			{
				"box" : 				{
					"id" : "obj-hint",
					"maxclass" : "comment",
					"numinlets" : 1,
					"numoutlets" : 0,
					"patching_rect" : [ 30.0, 42.0, 500.0, 20.0 ],
					"text" : "Pick a chord from the menu, then ping/send. npm install once. Pick model and session below."
				}

			}
, 			{
				"box" : 				{
					"id" : "obj-input-label",
					"maxclass" : "comment",
					"numinlets" : 1,
					"numoutlets" : 0,
					"patching_rect" : [ 30.0, 80.0, 120.0, 20.0 ],
					"text" : "chord"
				}

			}
, 			{
				"box" : 				{
					"id" : "obj-chord-menu",
					"maxclass" : "umenu",
					"numinlets" : 1,
					"numoutlets" : 3,
					"outlettype" : [ "int", "", "" ],
					"parameter_enable" : 0,
					"patching_rect" : [ 30.0, 105.0, 120.0, 22.0 ],
					"items" : [ "C:maj7", ",", "G:7", ",", "C:maj", ",", "D:min7", ",", "A:min7", ",", "F:maj7", ",", "E:7", ",", "A:7", ",", "D:7", ",", "B:min7", ",", "G:min7", ",", "A-:7", ",", "F:min7" ]
				}

			}
, 			{
				"box" : 				{
					"id" : "obj-btn-send",
					"maxclass" : "textbutton",
					"numinlets" : 1,
					"numoutlets" : 3,
					"outlettype" : [ "", "", "" ],
					"parameter_enable" : 0,
					"patching_rect" : [ 170.0, 105.0, 60.0, 22.0 ],
					"text" : "send"
				}

			}
, 			{
				"box" : 				{
					"id" : "obj-btn-ping",
					"maxclass" : "textbutton",
					"numinlets" : 1,
					"numoutlets" : 3,
					"outlettype" : [ "", "", "" ],
					"parameter_enable" : 0,
					"patching_rect" : [ 250.0, 105.0, 60.0, 22.0 ],
					"text" : "ping"
				}

			}
, 			{
				"box" : 				{
					"id" : "obj-btn-reload",
					"maxclass" : "textbutton",
					"numinlets" : 1,
					"numoutlets" : 3,
					"outlettype" : [ "", "", "" ],
					"parameter_enable" : 0,
					"patching_rect" : [ 330.0, 105.0, 60.0, 22.0 ],
					"text" : "reload"
				}

			}
, 			{
				"box" : 				{
					"id" : "obj-btn-npm",
					"maxclass" : "textbutton",
					"numinlets" : 1,
					"numoutlets" : 3,
					"outlettype" : [ "", "", "" ],
					"parameter_enable" : 0,
					"patching_rect" : [ 410.0, 105.0, 90.0, 22.0 ],
					"text" : "npm install"
				}

			}
, 			{
				"box" : 				{
					"id" : "obj-btn-restart",
					"maxclass" : "textbutton",
					"numinlets" : 1,
					"numoutlets" : 3,
					"outlettype" : [ "", "", "" ],
					"parameter_enable" : 0,
					"patching_rect" : [ 510.0, 105.0, 90.0, 22.0 ],
					"text" : "restart js"
				}

			}
, 			{
				"box" : 				{
					"id" : "obj-model-label",
					"maxclass" : "comment",
					"numinlets" : 1,
					"numoutlets" : 0,
					"patching_rect" : [ 30.0, 175.0, 120.0, 20.0 ],
					"text" : "model"
				}

			}
, 			{
				"box" : 				{
					"id" : "obj-model-menu",
					"maxclass" : "umenu",
					"numinlets" : 1,
					"numoutlets" : 3,
					"outlettype" : [ "int", "", "" ],
					"parameter_enable" : 0,
					"patching_rect" : [ 30.0, 200.0, 120.0, 22.0 ],
					"items" : [ "markov", ",", "rnn", ",", "lstm" ]
				}

			}
, 			{
				"box" : 				{
					"id" : "obj-session-label",
					"maxclass" : "comment",
					"numinlets" : 1,
					"numoutlets" : 0,
					"patching_rect" : [ 280.0, 175.0, 120.0, 20.0 ],
					"text" : "session"
				}

			}
, 			{
				"box" : 				{
					"id" : "obj-session-menu",
					"maxclass" : "umenu",
					"numinlets" : 1,
					"numoutlets" : 3,
					"outlettype" : [ "int", "", "" ],
					"parameter_enable" : 0,
					"patching_rect" : [ 280.0, 200.0, 120.0, 22.0 ],
					"items" : [ "auto", ",", "stateless", ",", "session" ]
				}

			}
, 			{
				"box" : 				{
					"id" : "obj-prepend-session",
					"maxclass" : "newobj",
					"numinlets" : 1,
					"numoutlets" : 1,
					"outlettype" : [ "" ],
					"patching_rect" : [ 420.0, 200.0, 105.0, 22.0 ],
					"text" : "prepend session"
				}

			}
, 			{
				"box" : 				{
					"id" : "obj-btn-reset-session",
					"maxclass" : "textbutton",
					"numinlets" : 1,
					"numoutlets" : 3,
					"outlettype" : [ "", "", "" ],
					"parameter_enable" : 0,
					"patching_rect" : [ 540.0, 200.0, 90.0, 22.0 ],
					"text" : "reset session"
				}

			}
, 			{
				"box" : 				{
					"id" : "obj-msg-reset-session",
					"maxclass" : "message",
					"numinlets" : 2,
					"numoutlets" : 1,
					"outlettype" : [ "" ],
					"patching_rect" : [ 540.0, 170.0, 90.0, 22.0 ],
					"text" : "reset_session"
				}

			}
, 			{
				"box" : 				{
					"id" : "obj-session-display-label",
					"maxclass" : "comment",
					"numinlets" : 1,
					"numoutlets" : 0,
					"patching_rect" : [ 780.0, 260.0, 80.0, 20.0 ],
					"text" : "session"
				}

			}
, 			{
				"box" : 				{
					"id" : "obj-session-display",
					"maxclass" : "message",
					"numinlets" : 2,
					"numoutlets" : 1,
					"outlettype" : [ "" ],
					"patching_rect" : [ 780.0, 285.0, 120.0, 22.0 ],
					"text" : "set stateless 0"
				}

			}
, 			{
				"box" : 				{
					"id" : "obj-prepend-set-session",
					"maxclass" : "newobj",
					"numinlets" : 1,
					"numoutlets" : 1,
					"outlettype" : [ "" ],
					"patching_rect" : [ 780.0, 240.0, 65.0, 22.0 ],
					"text" : "prepend set"
				}

			}
, 			{
				"box" : 				{
					"id" : "obj-pack-session",
					"maxclass" : "newobj",
					"numinlets" : 2,
					"numoutlets" : 1,
					"outlettype" : [ "" ],
					"patching_rect" : [ 780.0, 210.0, 60.0, 22.0 ],
					"text" : "pack s i"
				}

			}
, 			{
				"box" : 				{
					"id" : "obj-prepend-model",
					"maxclass" : "newobj",
					"numinlets" : 1,
					"numoutlets" : 1,
					"outlettype" : [ "" ],
					"patching_rect" : [ 170.0, 200.0, 95.0, 22.0 ],
					"text" : "prepend model"
				}

			}
, 			{
				"box" : 				{
					"id" : "obj-model-display-label",
					"maxclass" : "comment",
					"numinlets" : 1,
					"numoutlets" : 0,
					"patching_rect" : [ 620.0, 260.0, 80.0, 20.0 ],
					"text" : "active model"
				}

			}
, 			{
				"box" : 				{
					"id" : "obj-model-display",
					"maxclass" : "message",
					"numinlets" : 2,
					"numoutlets" : 1,
					"outlettype" : [ "" ],
					"patching_rect" : [ 620.0, 285.0, 120.0, 22.0 ],
					"text" : "set markov"
				}

			}
, 			{
				"box" : 				{
					"id" : "obj-prepend-set-chord",
					"maxclass" : "newobj",
					"numinlets" : 1,
					"numoutlets" : 1,
					"outlettype" : [ "" ],
					"patching_rect" : [ 30.0, 135.0, 65.0, 22.0 ],
					"text" : "prepend set"
				}

			}
, 			{
				"box" : 				{
					"id" : "obj-chord-store",
					"maxclass" : "message",
					"numinlets" : 2,
					"numoutlets" : 1,
					"outlettype" : [ "" ],
					"patching_rect" : [ 105.0, 135.0, 80.0, 22.0 ],
					"text" : "C:maj7"
				}

			}
, 			{
				"box" : 				{
					"id" : "obj-prepend-chord",
					"maxclass" : "newobj",
					"numinlets" : 1,
					"numoutlets" : 1,
					"outlettype" : [ "" ],
					"patching_rect" : [ 30.0, 165.0, 90.0, 22.0 ],
					"text" : "prepend chord"
				}

			}
, 			{
				"box" : 				{
					"id" : "obj-msg-npm",
					"maxclass" : "message",
					"numinlets" : 2,
					"numoutlets" : 1,
					"outlettype" : [ "" ],
					"patching_rect" : [ 410.0, 140.0, 100.0, 22.0 ],
					"text" : "script npm install"
				}

			}
, 			{
				"box" : 				{
					"id" : "obj-msg-ping",
					"maxclass" : "message",
					"numinlets" : 2,
					"numoutlets" : 1,
					"outlettype" : [ "" ],
					"patching_rect" : [ 250.0, 140.0, 35.0, 22.0 ],
					"text" : "ping"
				}

			}
, 			{
				"box" : 				{
					"id" : "obj-msg-reload",
					"maxclass" : "message",
					"numinlets" : 2,
					"numoutlets" : 1,
					"outlettype" : [ "" ],
					"patching_rect" : [ 330.0, 140.0, 45.0, 22.0 ],
					"text" : "reload"
				}

			}
, 			{
				"box" : 				{
					"id" : "obj-msg-restart",
					"maxclass" : "message",
					"numinlets" : 2,
					"numoutlets" : 1,
					"outlettype" : [ "" ],
					"patching_rect" : [ 510.0, 140.0, 70.0, 22.0 ],
					"text" : "script stop"
				}

			}
, 			{
				"box" : 				{
					"id" : "obj-msg-restart2",
					"maxclass" : "message",
					"numinlets" : 2,
					"numoutlets" : 1,
					"outlettype" : [ "" ],
					"patching_rect" : [ 510.0, 170.0, 70.0, 22.0 ],
					"text" : "script start"
				}

			}
, 			{
				"box" : 				{
					"id" : "obj-node",
					"maxclass" : "newobj",
					"numinlets" : 1,
					"numoutlets" : 1,
					"outlettype" : [ "" ],
					"patching_rect" : [ 250.0, 210.0, 150.0, 22.0 ],
					"text" : "node.script markov_osc.js",
					"filename" : "markov_osc.js"
				}

			}
, 			{
				"box" : 				{
					"id" : "obj-route",
					"maxclass" : "newobj",
					"numinlets" : 1,
					"numoutlets" : 6,
					"outlettype" : [ "", "", "", "", "", "" ],
					"patching_rect" : [ 450.0, 210.0, 160.0, 22.0 ],
					"text" : "route status output error model session"
				}

			}
, 			{
				"box" : 				{
					"id" : "obj-status-label",
					"maxclass" : "comment",
					"numinlets" : 1,
					"numoutlets" : 0,
					"patching_rect" : [ 450.0, 260.0, 80.0, 20.0 ],
					"text" : "status"
				}

			}
, 			{
				"box" : 				{
					"id" : "obj-status",
					"maxclass" : "message",
					"numinlets" : 2,
					"numoutlets" : 1,
					"outlettype" : [ "" ],
					"patching_rect" : [ 450.0, 285.0, 120.0, 22.0 ],
					"text" : "set $1"
				}

			}
, 			{
				"box" : 				{
					"id" : "obj-output-label",
					"maxclass" : "comment",
					"numinlets" : 1,
					"numoutlets" : 0,
					"patching_rect" : [ 450.0, 320.0, 80.0, 20.0 ],
					"text" : "output"
				}

			}
, 			{
				"box" : 				{
					"id" : "obj-output",
					"maxclass" : "message",
					"numinlets" : 2,
					"numoutlets" : 1,
					"outlettype" : [ "" ],
					"patching_rect" : [ 450.0, 345.0, 150.0, 22.0 ],
					"text" : "set $1"
				}

			}
, 			{
				"box" : 				{
					"id" : "obj-error-label",
					"maxclass" : "comment",
					"numinlets" : 1,
					"numoutlets" : 0,
					"patching_rect" : [ 450.0, 380.0, 80.0, 20.0 ],
					"text" : "error"
				}

			}
, 			{
				"box" : 				{
					"id" : "obj-error",
					"maxclass" : "message",
					"numinlets" : 2,
					"numoutlets" : 1,
					"outlettype" : [ "" ],
					"patching_rect" : [ 450.0, 405.0, 220.0, 22.0 ],
					"text" : "set $1"
				}

			}
, 			{
				"box" : 				{
					"id" : "obj-outlet",
					"maxclass" : "newobj",
					"numinlets" : 1,
					"numoutlets" : 0,
					"patching_rect" : [ 620.0, 345.0, 60.0, 22.0 ],
					"text" : "out s"
				}

			}
, 			{
				"box" : 				{
					"id" : "obj-print-status",
					"maxclass" : "newobj",
					"numinlets" : 1,
					"numoutlets" : 0,
					"patching_rect" : [ 580.0, 285.0, 70.0, 22.0 ],
					"text" : "print status"
				}

			}
, 			{
				"box" : 				{
					"id" : "obj-print-output",
					"maxclass" : "newobj",
					"numinlets" : 1,
					"numoutlets" : 0,
					"patching_rect" : [ 620.0, 375.0, 55.0, 22.0 ],
					"text" : "print output"
				}

			}
, 			{
				"box" : 				{
					"id" : "obj-print-error",
					"maxclass" : "newobj",
					"numinlets" : 1,
					"numoutlets" : 0,
					"patching_rect" : [ 450.0, 440.0, 45.0, 22.0 ],
					"text" : "print error"
				}

			}
, 			{
				"box" : 				{
					"id" : "obj-loadbang",
					"maxclass" : "newobj",
					"numinlets" : 1,
					"numoutlets" : 1,
					"outlettype" : [ "bang" ],
					"patching_rect" : [ 250.0, 55.0, 60.0, 22.0 ],
					"text" : "loadbang"
				}

			}
, 			{
				"box" : 				{
					"id" : "obj-msg-start",
					"maxclass" : "message",
					"numinlets" : 2,
					"numoutlets" : 1,
					"outlettype" : [ "" ],
					"patching_rect" : [ 250.0, 140.0, 70.0, 22.0 ],
					"text" : "script start"
				}

			}
, 			{
				"box" : 				{
					"id" : "obj-init-delay",
					"maxclass" : "newobj",
					"numinlets" : 2,
					"numoutlets" : 1,
					"outlettype" : [ "bang" ],
					"patching_rect" : [ 250.0, 80.0, 55.0, 22.0 ],
					"text" : "delay 300"
				}

			}
, 			{
				"box" : 				{
					"id" : "obj-ping-delay",
					"maxclass" : "newobj",
					"numinlets" : 2,
					"numoutlets" : 1,
					"outlettype" : [ "bang" ],
					"patching_rect" : [ 330.0, 170.0, 55.0, 22.0 ],
					"text" : "delay 200"
				}

			}
, 			{
				"box" : 				{
					"id" : "obj-msg-init",
					"maxclass" : "message",
					"numinlets" : 2,
					"numoutlets" : 1,
					"outlettype" : [ "" ],
					"patching_rect" : [ 330.0, 140.0, 35.0, 22.0 ],
					"text" : "init"
				}

			}
, 			{
				"box" : 				{
					"id" : "obj-status-wait",
					"maxclass" : "message",
					"numinlets" : 2,
					"numoutlets" : 1,
					"outlettype" : [ "" ],
					"patching_rect" : [ 580.0, 255.0, 55.0, 22.0 ],
					"text" : "waiting"
				}

			}
 ],
		"lines" : [ 			{
				"patchline" : 				{
					"destination" : [ "obj-msg-npm", 0 ],
					"source" : [ "obj-btn-npm", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-node", 0 ],
					"source" : [ "obj-msg-npm", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-msg-restart", 0 ],
					"source" : [ "obj-btn-restart", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-node", 0 ],
					"source" : [ "obj-msg-restart", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-msg-restart2", 0 ],
					"source" : [ "obj-msg-restart", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-node", 0 ],
					"source" : [ "obj-msg-restart2", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-msg-ping", 0 ],
					"source" : [ "obj-btn-ping", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-node", 0 ],
					"source" : [ "obj-msg-ping", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-msg-reload", 0 ],
					"source" : [ "obj-btn-reload", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-node", 0 ],
					"source" : [ "obj-msg-reload", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-chord-store", 0 ],
					"source" : [ "obj-btn-send", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-prepend-set-chord", 0 ],
					"source" : [ "obj-chord-menu", 1 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-chord-store", 0 ],
					"source" : [ "obj-prepend-set-chord", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-prepend-chord", 0 ],
					"source" : [ "obj-chord-store", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-node", 0 ],
					"source" : [ "obj-prepend-chord", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-route", 0 ],
					"source" : [ "obj-node", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-status", 0 ],
					"source" : [ "obj-route", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-print-status", 0 ],
					"source" : [ "obj-status", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-output", 0 ],
					"source" : [ "obj-route", 1 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-outlet", 0 ],
					"source" : [ "obj-route", 1 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-print-output", 0 ],
					"source" : [ "obj-output", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-error", 0 ],
					"source" : [ "obj-route", 2 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-print-error", 0 ],
					"source" : [ "obj-error", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-init-delay", 0 ],
					"source" : [ "obj-loadbang", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-msg-start", 0 ],
					"source" : [ "obj-init-delay", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-node", 0 ],
					"source" : [ "obj-msg-start", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-ping-delay", 0 ],
					"source" : [ "obj-msg-start", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-msg-init", 0 ],
					"source" : [ "obj-ping-delay", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-node", 0 ],
					"source" : [ "obj-msg-init", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-prepend-model", 0 ],
					"source" : [ "obj-model-menu", 1 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-node", 0 ],
					"source" : [ "obj-prepend-model", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-model-display", 0 ],
					"source" : [ "obj-route", 3 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-session-display", 0 ],
					"source" : [ "obj-route", 4 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-prepend-session", 0 ],
					"source" : [ "obj-session-menu", 1 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-node", 0 ],
					"source" : [ "obj-prepend-session", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-msg-reset-session", 0 ],
					"source" : [ "obj-btn-reset-session", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-node", 0 ],
					"source" : [ "obj-msg-reset-session", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-status-wait", 0 ],
					"source" : [ "obj-loadbang", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-status", 0 ],
					"source" : [ "obj-status-wait", 0 ]
				}

			}
 ]
	}

}
