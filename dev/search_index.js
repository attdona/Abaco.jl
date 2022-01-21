var documenterSearchIndex = {"docs":
[{"location":"","page":"Home","title":"Home","text":"CurrentModule = Abaco","category":"page"},{"location":"#Abaco","page":"Home","title":"Abaco","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Abaco computes formulas output from a stream of metric values as soon as all needed input values are collected.","category":"page"},{"location":"","page":"Home","title":"Home","text":"In a real world scenario values are coming asynchronously, delayed and out of orders. Abaco may manage values referring to different times.","category":"page"},{"location":"#Basic-Concepts","page":"Home","title":"Basic Concepts","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"An input value is associated with a node entity identified by a unique name.","category":"page"},{"location":"","page":"Home","title":"Home","text":"A node may be seen as a data source or a data fusion domain: all variables that belong to the same node can be used by some formula. ","category":"page"},{"location":"","page":"Home","title":"Home","text":"Abaco manages a hierarchy of nodes, more on that later.","category":"page"},{"location":"","page":"Home","title":"Home","text":"A node must be provisioned before sending metric values associated with the node:","category":"page"},{"location":"","page":"Home","title":"Home","text":"julia> add_node(abaco, \"my_node\") ","category":"page"},{"location":"","page":"Home","title":"Home","text":"A metric data point is a measure associated with a node. A metric is defined by: ","category":"page"},{"location":"","page":"Home","title":"Home","text":"a node unique name      \na timestamp\na metric name\na metric value","category":"page"},{"location":"","page":"Home","title":"Home","text":"Abaco understands metric values ingested in a \"flat\" Dict{String,Any}.","category":"page"},{"location":"","page":"Home","title":"Home","text":"en and ts are reserved keyword for the unique node name and the timestamp whereas the others properties represent metrics values.","category":"page"},{"location":"","page":"Home","title":"Home","text":"A record with a single metric example:","category":"page"},{"location":"","page":"Home","title":"Home","text":"julia> x_metric = Dict(\n    \"en\" => \"my_network_element\",\n    \"ts\" => 1642605647,\n    \"x\" => 1.5\n)\n\njulia> y_metric = Dict(\n    \"en\" => \"my_network_element\",\n    \"ts\" => 1642605647,\n    \"y\" => 8.5\n)\n","category":"page"},{"location":"","page":"Home","title":"Home","text":"And a record with a batch of metrics:","category":"page"},{"location":"","page":"Home","title":"Home","text":"julia> metrics = Dict(\n    \"en\" => \"my_network_element\",\n    \"ts\" => 1642605647,\n    \"x\" => 1.5,\n    \"y\" => 25,\n    \"z\" => 999\n)","category":"page"},{"location":"","page":"Home","title":"Home","text":"Metrics names are the names of the indipendent variables used by Abaco formulas.","category":"page"},{"location":"","page":"Home","title":"Home","text":"A formula is named math expression defined by a string:","category":"page"},{"location":"","page":"Home","title":"Home","text":"                        # formula name   expr\njulia> add_formula(abaco, \"my_formula\", \"x + y\")","category":"page"},{"location":"","page":"Home","title":"Home","text":"As soon as all inputs variables are collected and belong to the same time window the formula result is calculated.","category":"page"},{"location":"","page":"Home","title":"Home","text":"Using the above example as soon as both x and y are collected formula my_formula is evaluated and onresult default callback is triggered.","category":"page"},{"location":"","page":"Home","title":"Home","text":"The default callback print the result summary to the console.","category":"page"},{"location":"","page":"Home","title":"Home","text":"julia> add_metrics(abaco, x_metric)\n\njulia> add_metrics(abaco, y_metric)\nmy_formula(ts:1642605647, sn:my_network_element) = 10.0","category":"page"},{"location":"#time-span","page":"Home","title":"time span","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"A time span includes all the timestamps in a time interval:","category":"page"},{"location":"","page":"Home","title":"Home","text":"span = { t ∈ N | START_INTERVAL <= t < END_TIME }","category":"page"},{"location":"","page":"Home","title":"Home","text":"Timestamps t are integer values with second granularity. ","category":"page"},{"location":"","page":"Home","title":"Home","text":"For example suppose that a data collection system uses a 15 minutes span interval: in this case an hour is divided into 4 intervals and from ten to eleven of some (omitted) day you have:","category":"page"},{"location":"","page":"Home","title":"Home","text":"span1 =  { t ∈ [10:00:00, 10:15:00) }\nspan2 =  { t ∈ [10:15:00, 10:30:00) }\nspan3 =  { t ∈ [10:30:00, 10:45:00) }\nspan4 =  { t ∈ [10:45:00, 11:00:00) }","category":"page"},{"location":"","page":"Home","title":"Home","text":"By convention the span interval is identified by its START_TIME.","category":"page"},{"location":"","page":"Home","title":"Home","text":"The formula value computed from inputs with timestamps included into the span [START_TIME, END_TIME) has timestamp equal to START_TIME.","category":"page"},{"location":"","page":"Home","title":"Home","text":"The width of the span interval is an abaco setting, user-defined at startup.","category":"page"},{"location":"#ages","page":"Home","title":"ages","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"The number of ages defines how many consecutive time spans are managed.","category":"page"},{"location":"","page":"Home","title":"Home","text":"For example, for a time span of 15 minutes, set ages to 4 if your network devices may send data with a maximum delay of an hour. A received value marked with a timestamp distant 4 or more spans from the latest span is discarded.","category":"page"},{"location":"","page":"Home","title":"Home","text":"The number of ages is an abaco setting, user-defined at startup.","category":"page"},{"location":"","page":"Home","title":"Home","text":"This is the minimal background theory, the below example should help to clarify the Abaco mechanics.","category":"page"},{"location":"#Getting-Started","page":"Home","title":"Getting Started","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Installation:","category":"page"},{"location":"","page":"Home","title":"Home","text":"julia> using Pkg; Pkg.add(\"Abaco\")    ","category":"page"},{"location":"","page":"Home","title":"Home","text":"Usage:","category":"page"},{"location":"","page":"Home","title":"Home","text":"using Abaco\n\n# Initialize abaco context with a time_window of 60 seconds and handle\n# input values with timestamp ts up to 4 contiguous spans.\nabaco = abaco_init(interval=60, ages=4) do ts, node, formula_name, value, inputs\n    @info \"[$ts][$node] function $formula_name=$value\"\nend\n\n# Add desired outputs in terms of inputs variables x, y, z, v, w\noutputs = [\"xysum = x + y\", \"rsigma = x * exp(y-1)\", \"wsum = (x*w + z*v)\"]\n\nfor formula in outputs\n    add_formula(abaco, formula)\nend\n\n# Start receiving some inputs values\n# normally ts is the UTC timestamp from epoch in seconds.\n# but for semplicity assume time start from zero.\n\n# the node AG101 sends the x value at timestamp 0.\nts = 0\nnode = \"AG101\"\nadd_value(abaco, ts, node, \"x\", 10)\n\n# Time flows and about 1 minute later ...\n\n# the node CE987 sends the y value at timestamp 65.\nts = 65\nnode = \"CE987\"\nadd_value(abaco, ts, node, \"y\", 10)\n\n# Time flows and more than 1 minute later ...\n\n# Finally the node AG101 sends the y value calculated at timestamp 0.\n# At this instant the formulas that depends on x and y are computable\n# for the element AG101 at timestamp 0.\nts = 0\nnode = \"AG101\"\nadd_value(abaco, ts, node, \"y\", 20)\n[ Info: [0][AG101] function xysum=30\n[ Info: [0][AG101] function rsigma=1.7848230096318724e9\n\n# Now arrives the variable x from CE987 that make some formulas computables.\n# Note that x timestamp is 65, y timestamp is 101\n# and the formulas timestamp is 60: the START_TIME of the span. \nts = 101\nnode = \"CE987\"\nadd_value(abaco, ts, node, \"x\", 10)\n[ Info: [60][CE987] function xysum=20\n[ Info: [60][CE987] function rsigma=81030.83927575384\n","category":"page"},{"location":"","page":"Home","title":"Home","text":"In the formula callback the first argument may be a user defined object, like a Socket a Channel or whatsoever communication endpoint.","category":"page"},{"location":"","page":"Home","title":"Home","text":"For example:","category":"page"},{"location":"","page":"Home","title":"Home","text":"sock = connect(3001)\n\nabaco = abaco_init(handle=sock, interval=900) do sock, ts, node, formula_name, value, inputs\n    @info \"age [$ts]: [$node] $formula_name = $value\"\n    msg = JSON3.write(Dict(\n                        \"node\" => node,\n                        \"age\" => ts, \n                        \"formula\" => formula_name,\n                        \"value\" => value))\n    write(sock, msg*\"\\n\")\nend","category":"page"},{"location":"#API","page":"Home","title":"API","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"","category":"page"},{"location":"","page":"Home","title":"Home","text":"Modules = [Abaco]","category":"page"},{"location":"#Abaco.Context","page":"Home","title":"Abaco.Context","text":"The abaco registry. \n\n\n\n\n\n","category":"type"},{"location":"#Abaco.EvalError","page":"Home","title":"Abaco.EvalError","text":"Formula evaluation failure.\n\n[add_value] throws EvalError when a runtime formula evaluation fails, for example for a wrong numbers of method args:\n\nadd_formula(abaco, \"div(x,y,z\")\nadd_value(abaco, ts, sn, Dict(\"x\"=>10, \"y\"=>1, \"z\"=1))\n\n\n\n\n\n","category":"type"},{"location":"#Abaco.Snap","page":"Home","title":"Abaco.Snap","text":"Maintains the state of the abaco.\n\nBefore adding formulas and values an abaco MonoContext must be initialized by abaco_init.\n\n\n\n\n\n","category":"type"},{"location":"#Abaco.SnapsSetting","page":"Home","title":"Abaco.SnapsSetting","text":"The settings of snapshots.\n\nBefore adding formulas and values the SnapsSetting must be initialized by abaco_init.\n\n\n\n\n\n","category":"type"},{"location":"#Abaco.ValueNotFound","page":"Home","title":"Abaco.ValueNotFound","text":"Attempt to get a value with an invalid index.\n\n\n\n\n\n","category":"type"},{"location":"#Abaco.WrongFormula","page":"Home","title":"Abaco.WrongFormula","text":"Wrong formula definition.\n\nadd_formula throws WrongFormula when a formula is malformed, for example:\n\nadd_formula(abaco, \"myformula = x + \")\n\n\n\n\n\n","category":"type"},{"location":"#Abaco.abaco_init-Tuple{Any}","page":"Home","title":"Abaco.abaco_init","text":"abaco_init(onresult; handle=nothing, interval::Int=900, ages::Int=4, emitone=true)::Context\n\nInitialize the abaco context:\n\nonresult: function callback that gets called each time a formula value is computed.\nhandle: user defined object.            If handle is defined it is the first argument of onresult, default to nothing.\ninterval: the span interval in seconds, default to 900 seconds (15 minutes).             If interval is equal to -1 there is just one infinite time span.\nages: the number of active rops managed by the abaco. Default to 4.         If interval is equal to -1 ages  is not applicable because it loses meaning.\nemitone: if true emits for each time span at most 1 formula value,             otherwise emits a new result at every new inputs. Defaut to true\n\nExample 1: defining onresult callback that uses of an handle object.\n\n# the handle object is a socket\nsock = connect(3001)\n\nfunction onresult(handle, ts, sn, formula_name, value, inputs)\n    # build a pkt message from ts, sn, ...\n    pkt = ...\n    write(sock, pkt)\nend\n\nExample 2: defining onresult callback that doesn't use an handle object.\n\nabaco = abaco_init(onresult, handle=sock)\n\nfunction onresult(ts, sn, formula_name, value, inputs)\n    @info \"[$ts][$sn] function $fname=$value\"\nend\n\nabaco = abaco_init(onresult)\n\n\n\n\n\n","category":"method"},{"location":"#Abaco.add_formula-Tuple{Abaco.SnapsSetting, Any, Any}","page":"Home","title":"Abaco.add_formula","text":"add_formula(setting::SnapsSetting, name, expression)\n\nAdd the formula name defined by expression: a mathematical expression like x + y*w.\n\n\n\n\n\n","category":"method"},{"location":"#Abaco.add_formula-Tuple{Abaco.SnapsSetting, Any}","page":"Home","title":"Abaco.add_formula","text":"add_formula(setting::SnapsSetting, formula_def::String)\n\nAdd a formula, with formula_def formatted as \"formula_name = expression\", where expression is a mathematical expression, like x + y*w.\n\n\n\n\n\n","category":"method"},{"location":"#Abaco.add_formulas-Tuple{Any, Any}","page":"Home","title":"Abaco.add_formulas","text":"\n\n\n\n","category":"method"},{"location":"#Abaco.add_value-Tuple{Any, Int64, String, String, Real}","page":"Home","title":"Abaco.add_value","text":"add_value(abaco, ts::Int, sn::String, var::String, val::Real)\n\nAdds the input variable var with value val.\n\nts: timestamp with seconds resolution\nsn: scope name \nvar: variable name\nval: variable value\n\n\n\n\n\n","category":"method"},{"location":"#Abaco.add_values!-Tuple{Any, Any}","page":"Home","title":"Abaco.add_values!","text":"add_values!(abaco, payload)\n\nAdds the input variables included in the payload dictionary.\n\nThe Dict msg must contains the keys ts and sn and a numbers of other keys managed as input variables.\n\nThis function modifies the payload dictionary: sn and ts keys are popped out.  \n\n    payload = Dict(\n        \"ts\" => nowts(),\n        \"sn\" => \"trento.castello\",\n        \"x\" => 23.2,\n        \"y\" => 100\n    )\n    add_values!(abaco, ts, sn, payload)\n\n\n\n\n\n","category":"method"},{"location":"#Abaco.add_values-NTuple{4, Any}","page":"Home","title":"Abaco.add_values","text":"add_values(abaco, ts, sn, values)\n\nAdds the input variables include in the dictionary values.\n\n    # now timestamp \n    ts = nowts()\n\n    # short name of network element\n    sn = \"trento.castello\"\n\n    values = Dict(\n        \"x\" => 23.2,\n        \"y\" => 100\n    )\n    add_values(abaco, ts, sn, values)\n\n\n\n\n\n","category":"method"},{"location":"#Abaco.dependents-Tuple{Context, String, String}","page":"Home","title":"Abaco.dependents","text":"dependents(abaco::Context, domain::String, var::String)\n\nReturns the list of expressions that depends on var.\n\n\n\n\n\n","category":"method"},{"location":"#Abaco.getsnap-Tuple{Context, Any, Any}","page":"Home","title":"Abaco.getsnap","text":"getsnap(abaco::Context, ts, sn)\n\nReturns the sn element snapshot relative to timestamp ts.\n\n\n\n\n\n","category":"method"},{"location":"#Abaco.lastspan","page":"Home","title":"Abaco.lastspan","text":"lastspan(interval::Int64=900)::Int64\n\nReturns the epoch start time of the last span. The last span is the nearest in the present time interval that satisfies the condition: span.endtime < now.\n\n\n\n\n\n","category":"function"},{"location":"#Abaco.nowts","page":"Home","title":"Abaco.nowts","text":"nowts()\n\nthe current timestamp in seconds from epoch\n\n\n\n\n\n","category":"function"},{"location":"#Abaco.snap_add-Tuple{Abaco.Snap, Any, String, Real}","page":"Home","title":"Abaco.snap_add","text":"snap_add(snap::Snap, sn, var::String, val::Real)\n\nAdds the variable value of sn element to the snap snapshot. \n\n\n\n\n\n","category":"method"},{"location":"#Abaco.span","page":"Home","title":"Abaco.span","text":"span(ts::Int64, interval::Int64=900)\n\nReturns the start_time of the time interval that contains ts.\n\n\n\n\n\n","category":"function"}]
}
