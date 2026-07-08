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
		"rect" : [ 100.0, 100.0, 900.0, 620.0 ],
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
					"patching_rect" : [ 30.0, 20.0, 320.0, 20.0 ],
					"text" : "Markov Chord Device v1 — requires CNMAT o.pack / o.route"
				}

			}
, 			{
				"box" : 				{
					"id" : "obj-input-label",
					"maxclass" : "comment",
					"numinlets" : 1,
					"numoutlets" : 0,
					"patching_rect" : [ 30.0, 55.0, 80.0, 20.0 ],
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
					"patching_rect" : [ 30.0, 80.0, 120.0, 22.0 ],
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
					"patching_rect" : [ 170.0, 80.0, 60.0, 22.0 ],
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
					"patching_rect" : [ 250.0, 80.0, 60.0, 22.0 ],
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
					"patching_rect" : [ 330.0, 80.0, 60.0, 22.0 ],
					"text" : "reload"
				}

			}
, 			{
				"box" : 				{
					"id" : "obj-prepend-s",
					"maxclass" : "newobj",
					"numinlets" : 1,
					"numoutlets" : 1,
					"outlettype" : [ "" ],
					"patching_rect" : [ 30.0, 130.0, 70.0, 22.0 ],
					"text" : "prepend s"
				}

			}
, 			{
				"box" : 				{
					"id" : "obj-pack-input",
					"maxclass" : "newobj",
					"numinlets" : 1,
					"numoutlets" : 1,
					"outlettype" : [ "" ],
					"patching_rect" : [ 30.0, 165.0, 130.0, 22.0 ],
					"text" : "o.pack /chord/input"
				}

			}
, 			{
				"box" : 				{
					"id" : "obj-pack-ping",
					"maxclass" : "newobj",
					"numinlets" : 1,
					"numoutlets" : 1,
					"outlettype" : [ "" ],
					"patching_rect" : [ 250.0, 130.0, 130.0, 22.0 ],
					"text" : "o.pack /control/ping"
				}

			}
, 			{
				"box" : 				{
					"id" : "obj-pack-reload",
					"maxclass" : "newobj",
					"numinlets" : 1,
					"numoutlets" : 1,
					"outlettype" : [ "" ],
					"patching_rect" : [ 330.0, 130.0, 140.0, 22.0 ],
					"text" : "o.pack /control/reload"
				}

			}
, 			{
				"box" : 				{
					"id" : "obj-udpsend",
					"maxclass" : "newobj",
					"numinlets" : 1,
					"numoutlets" : 0,
					"patching_rect" : [ 170.0, 210.0, 150.0, 22.0 ],
					"text" : "udpsend 127.0.0.1 9000"
				}

			}
, 			{
				"box" : 				{
					"id" : "obj-t-send",
					"maxclass" : "newobj",
					"numinlets" : 1,
					"numoutlets" : 2,
					"outlettype" : [ "bang", "bang" ],
					"patching_rect" : [ 170.0, 115.0, 30.0, 22.0 ],
					"text" : "t b b"
				}

			}
, 			{
				"box" : 				{
					"id" : "obj-delay-timeout",
					"maxclass" : "newobj",
					"numinlets" : 2,
					"numoutlets" : 1,
					"outlettype" : [ "bang" ],
					"patching_rect" : [ 210.0, 145.0, 55.0, 22.0 ],
					"text" : "delay 500"
				}

			}
, 			{
				"box" : 				{
					"id" : "obj-timeout-msg",
					"maxclass" : "message",
					"numinlets" : 2,
					"numoutlets" : 1,
					"outlettype" : [ "" ],
					"patching_rect" : [ 210.0, 180.0, 130.0, 22.0 ],
					"text" : "reply timeout"
				}

			}
, 			{
				"box" : 				{
					"id" : "obj-stop-delay",
					"maxclass" : "message",
					"numinlets" : 2,
					"numoutlets" : 1,
					"outlettype" : [ "" ],
					"patching_rect" : [ 450.0, 320.0, 35.0, 22.0 ],
					"text" : "stop"
				}

			}
, 			{
				"box" : 				{
					"id" : "obj-udpreceive",
					"maxclass" : "newobj",
					"numinlets" : 1,
					"numoutlets" : 1,
					"outlettype" : [ "" ],
					"patching_rect" : [ 450.0, 80.0, 110.0, 22.0 ],
					"text" : "udpreceive 9001"
				}

			}
, 			{
				"box" : 				{
					"id" : "obj-route",
					"maxclass" : "newobj",
					"numinlets" : 1,
					"numoutlets" : 5,
					"outlettype" : [ "", "", "", "", "" ],
					"patching_rect" : [ 450.0, 120.0, 420.0, 22.0 ],
					"text" : "o.route /chord/output /status/ready /status/pong /error"
				}

			}
, 			{
				"box" : 				{
					"id" : "obj-output-label",
					"maxclass" : "comment",
					"numinlets" : 1,
					"numoutlets" : 0,
					"patching_rect" : [ 450.0, 170.0, 80.0, 20.0 ],
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
					"patching_rect" : [ 450.0, 195.0, 150.0, 22.0 ],
					"text" : "set $1"
				}

			}
, 			{
				"box" : 				{
					"id" : "obj-status-label",
					"maxclass" : "comment",
					"numinlets" : 1,
					"numoutlets" : 0,
					"patching_rect" : [ 620.0, 170.0, 80.0, 20.0 ],
					"text" : "status"
				}

			}
, 			{
				"box" : 				{
					"id" : "obj-status-ready",
					"maxclass" : "message",
					"numinlets" : 2,
					"numoutlets" : 1,
					"outlettype" : [ "" ],
					"patching_rect" : [ 620.0, 230.0, 55.0, 22.0 ],
					"text" : "ready"
				}

			}
, 			{
				"box" : 				{
					"id" : "obj-status-wait",
					"maxclass" : "message",
					"numinlets" : 2,
					"numoutlets" : 1,
					"outlettype" : [ "" ],
					"patching_rect" : [ 620.0, 195.0, 55.0, 22.0 ],
					"text" : "waiting"
				}

			}
, 			{
				"box" : 				{
					"id" : "obj-error-label",
					"maxclass" : "comment",
					"numinlets" : 1,
					"numoutlets" : 0,
					"patching_rect" : [ 450.0, 260.0, 80.0, 20.0 ],
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
					"patching_rect" : [ 450.0, 285.0, 220.0, 22.0 ],
					"text" : "set $1"
				}

			}
, 			{
				"box" : 				{
					"id" : "obj-outlet-label",
					"maxclass" : "comment",
					"numinlets" : 1,
					"numoutlets" : 0,
					"patching_rect" : [ 450.0, 330.0, 120.0, 20.0 ],
					"text" : "outlet (symbol)"
				}

			}
, 			{
				"box" : 				{
					"id" : "obj-outlet",
					"maxclass" : "newobj",
					"numinlets" : 1,
					"numoutlets" : 0,
					"patching_rect" : [ 450.0, 355.0, 60.0, 22.0 ],
					"text" : "out s"
				}

			}
, 			{
				"box" : 				{
					"id" : "obj-loadbang",
					"maxclass" : "newobj",
					"numinlets" : 1,
					"numoutlets" : 1,
					"outlettype" : [ "bang" ],
					"patching_rect" : [ 250.0, 30.0, 60.0, 22.0 ],
					"text" : "loadbang"
				}

			}
, 			{
				"box" : 				{
					"id" : "obj-init-delay",
					"maxclass" : "newobj",
					"numinlets" : 2,
					"numoutlets" : 1,
					"outlettype" : [ "bang" ],
					"patching_rect" : [ 250.0, 55.0, 55.0, 22.0 ],
					"text" : "delay 100"
				}

			}
, 			{
				"box" : 				{
					"id" : "obj-sel-ready",
					"maxclass" : "newobj",
					"numinlets" : 1,
					"numoutlets" : 2,
					"outlettype" : [ "int", "" ],
					"patching_rect" : [ 700.0, 230.0, 35.0, 22.0 ],
					"text" : "sel 1"
				}

			}
, 			{
				"box" : 				{
					"id" : "obj-print-status",
					"maxclass" : "newobj",
					"numinlets" : 1,
					"numoutlets" : 0,
					"patching_rect" : [ 620.0, 265.0, 40.0, 22.0 ],
					"text" : "print status"
				}

			}
, 			{
				"box" : 				{
					"id" : "obj-print-error",
					"maxclass" : "newobj",
					"numinlets" : 1,
					"numoutlets" : 0,
					"patching_rect" : [ 450.0, 320.0, 40.0, 22.0 ],
					"text" : "print error"
				}

			}
, 			{
				"box" : 				{
					"id" : "obj-print-output",
					"maxclass" : "newobj",
					"numinlets" : 1,
					"numoutlets" : 0,
					"patching_rect" : [ 450.0, 230.0, 50.0, 22.0 ],
					"text" : "print output"
				}

			}
 ],
		"lines" : [ 			{
				"patchline" : 				{
					"destination" : [ "obj-input", 0 ],
					"midpoints" : [ 179.5, 107.0, 39.5, 107.0 ],
					"source" : [ "obj-btn-send", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-t-send", 0 ],
					"source" : [ "obj-btn-send", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-input", 0 ],
					"midpoints" : [ 184.5, 107.0, 39.5, 107.0 ],
					"source" : [ "obj-t-send", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-delay-timeout", 0 ],
					"source" : [ "obj-t-send", 1 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-timeout-msg", 0 ],
					"source" : [ "obj-delay-timeout", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-error", 0 ],
					"source" : [ "obj-timeout-msg", 0 ]
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
					"destination" : [ "obj-prepend-s", 0 ],
					"source" : [ "obj-input", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-pack-input", 0 ],
					"source" : [ "obj-prepend-s", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-udpsend", 0 ],
					"midpoints" : [ 39.5, 200.0, 179.5, 200.0 ],
					"source" : [ "obj-pack-input", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-pack-ping", 0 ],
					"source" : [ "obj-btn-ping", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-udpsend", 0 ],
					"source" : [ "obj-pack-ping", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-pack-reload", 0 ],
					"source" : [ "obj-btn-reload", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-udpsend", 0 ],
					"source" : [ "obj-pack-reload", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-route", 0 ],
					"source" : [ "obj-udpreceive", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-output", 0 ],
					"source" : [ "obj-route", 0 ]
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
					"destination" : [ "obj-outlet", 0 ],
					"source" : [ "obj-route", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-stop-delay", 0 ],
					"source" : [ "obj-route", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-delay-timeout", 1 ],
					"midpoints" : [ 459.5, 350.0, 219.5, 350.0 ],
					"source" : [ "obj-stop-delay", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-sel-ready", 0 ],
					"source" : [ "obj-route", 1 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-sel-ready", 0 ],
					"source" : [ "obj-route", 2 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-status-ready", 0 ],
					"source" : [ "obj-sel-ready", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-print-status", 0 ],
					"source" : [ "obj-status-ready", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-error", 0 ],
					"source" : [ "obj-route", 3 ]
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
					"destination" : [ "obj-btn-ping", 0 ],
					"source" : [ "obj-init-delay", 0 ]
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
					"destination" : [ "obj-print-status", 0 ],
					"source" : [ "obj-status-wait", 0 ]
				}

			}
 ]
	}

}
