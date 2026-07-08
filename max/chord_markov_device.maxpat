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
		"rect" : [ 100.0, 100.0, 820.0, 520.0 ],
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
					"patching_rect" : [ 30.0, 20.0, 420.0, 20.0 ],
					"text" : "Markov Chord Device v1 — Node for Max OSC bridge (no CNMAT required)"
				}

			}
, 			{
				"box" : 				{
					"id" : "obj-hint",
					"maxclass" : "comment",
					"numinlets" : 1,
					"numoutlets" : 0,
					"patching_rect" : [ 30.0, 42.0, 420.0, 20.0 ],
					"text" : "First time only: click npm install, then ping. Start Python service first."
				}

			}
, 			{
				"box" : 				{
					"id" : "obj-input-label",
					"maxclass" : "comment",
					"numinlets" : 1,
					"numoutlets" : 0,
					"patching_rect" : [ 30.0, 80.0, 80.0, 20.0 ],
					"text" : "chord input"
				}

			}
, 			{
				"box" : 				{
					"id" : "obj-input",
					"maxclass" : "textedit",
					"numinlets" : 1,
					"numoutlets" : 1,
					"outlettype" : [ "text" ],
					"parameter_enable" : 0,
					"patching_rect" : [ 30.0, 105.0, 120.0, 22.0 ],
					"text" : "G:7"
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
					"id" : "obj-prepend-send",
					"maxclass" : "newobj",
					"numinlets" : 1,
					"numoutlets" : 1,
					"outlettype" : [ "" ],
					"patching_rect" : [ 30.0, 170.0, 80.0, 22.0 ],
					"text" : "prepend send"
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
					"numoutlets" : 4,
					"outlettype" : [ "", "", "", "" ],
					"patching_rect" : [ 450.0, 210.0, 130.0, 22.0 ],
					"text" : "route status output error"
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
					"patching_rect" : [ 450.0, 315.0, 70.0, 22.0 ],
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
					"patching_rect" : [ 250.0, 170.0, 35.0, 22.0 ],
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
					"patching_rect" : [ 580.0, 285.0, 55.0, 22.0 ],
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
					"destination" : [ "obj-input", 0 ],
					"source" : [ "obj-btn-send", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-prepend-send", 0 ],
					"source" : [ "obj-input", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-node", 0 ],
					"source" : [ "obj-prepend-send", 0 ]
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
