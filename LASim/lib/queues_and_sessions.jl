
# ==== Queue stuff

#
# what's sent to the client: a set for civil or aa
struct OneResponse{T}
    systype :: SystemType
    xlsxfile :: String
    html    :: NamedTuple
    default_params :: LASubsys{T}
    params  :: LASubsys{T}
end

# what;s cached/saved in session: a set of both aa and civil 
struct CompleteResponse{T}
    xlsxfile :: NamedTuple
    html    :: NamedTuple
    default_params :: AllLASubsys{T}
    params  :: AllLASubsys{T}
end

const DEFAULT_COMPLETE_RESPONSE = CompleteResponse(
    DEFAULT_XLSXFILE,
    DEFAULT_HTML,
    DEFAULT_SUBSYS,
    DEFAULT_SUBSYS
)

function OneResponse( systype :: SystemType, resp :: CompleteResponse ) :: OneResponse
    return if systype == civil
        OneResponse( systype, xlsxfile.civil, html.civil, default_params.civil, params.civil )
    else
        OneResponse( systype, xlsxfile.aa, html.aa, default_params.aa, params.aa )
    end
end

function to_session( res :: CompleteResponse )
    session = GenieSession.session()
    GenieSession.set!( session, :systype, res.systype )
    GenieSession.set!( session, :xlsxfile, res.xlsxfile )
    GenieSession.set!( session, :html, res.html )
    GenieSession.set!( session, :allsubsys, res.parans )
end

function from_session()::CompleteResponse 
    session = GenieSession.session()
    if( GenieSession.isset( session, :html ))
        return CompleteResponse(
            GenieSession.get( session, :systype ),
            GenieSession.get( session, :xlsxfile ),
            GenieSession.get( session, :html),
            GenieSession.get( session, :allsubsys ),
            DEFAULT_SUBSYS
        )
    else
        resp = deepcopy( DEFAULT_COMPLETE_RESPONSE )
        to_session( resp )
        return resp
    end
end

const CACHED_RESULTS = LRU{AllLASubsys,CompleteResponse}(maxsize=25)

function systype_from_session()
    session = GenieSession.session()
    systype = civil
    if( GenieSession.isset( session, :systype ))
        systype = GenieSession.get( session, :systype )
    else
        GenieSession.set!( session, :systype, systype )
    end
    return systype
end

function getprogress() 
    sess = GenieSession.session()
    systype = systype_from_session()
    @info "getprogress entered"
    progress = ( phase="missing", completed = 0, size=0 )
    if( GenieSession.isset( sess, :progress ))
        @info "getprogress: has progress"
        progress = GenieSession.get( sess, :progress )
    else
        @info "getprogress: no progress"
        GenieSession.set!( sess, :progress, progress )
    end
    ( response=has_progress, data=progress, systype=systype ) |> json
end
  
function session_obs(session::GenieSession.Session)::Observable
    obs = Observable( Progress(settings.uuid, "",0,0,0,0))
    completed = 0
    of = on(obs) do p
        if p.phase == "do-one-run-end"
            completed = 0
        end
        completed += p.step
        @info "monitor completed=$completed p = $(p)"
        GenieSession.set!( session, :progress, (phase=p.phase, completed = completed, size=p.size))
    end
    return obs
end 
  
function get_params_from_session()::AllLASubsys
    session = GenieSession.session()
    systype = systype_from_session()
    allsubsys = nothing
    if( GenieSession.isset( session, :allsubsys ))
        allsubsys = GenieSession.get( session, :allsubsys )
    else
        allsubsys = AllLASubSys( DEFAULT_PARAMS.legalaid )
        GenieSession.set!( session, :allsubsys, allsubsys )
    end
    return allsubsys
end

function reset()
    session = GenieSession.session()
    systype = systype_from_session()
    resp = deepcopy( DEFAULT_COMPLETE_RESPONSE )
    to_session( resp )
    return ( response=output_ready, data = OneResponse( systype, resp)) |> json``
end

function switch_system()
    systype = systype_from_session()
    systype = systype == civil ? aa : civil
    GenieSession.set!( session, :systype, systype )
    resp = from_session()
    return ( response=output_ready, data = OneResponse( systype, resp)) |> json``
end

"""
return output for the 
"""
function get_output() 
    systype = systype_from_session()
    resp = from_session()
    return ( response=output_ready, data = OneResponse( systype, resp)) |> json``
end

"""
Execute a run from the queue.
"""
function do_session_run( session::Session, allsubsys :: AllLASubsys )
    systype = systype_from_session()
    settings = make_default_settings()  
    lasys = map_sys_from_subsys( subsys )
    sys2 = deepcopy( DEFAULT_PARAMS )
    if subsys.systype == sys_civil 
        sys2.legalaid.civil = lasys
        allsubsys.civil = subsys
    else 
        sys2.legalaid.aa = lasys
        allsubsys.aa = subsys
    end
    map_settings_from_subsys!( settings, subsys )
    @info "dorun entered subsys is " subsys
    obs = session_obs(session)
    res.do_la_run( settings, DEFAULT_PARAMS, sys2, obs )
    # output = (; html, xlsxfile, params=allsubsys, defaults=default_subsys )
    obs[]=Progress( settings.uuid, "results-generation", 0, 0, 0, 0 )
    resp = CompleteResponse(
        systype,
        res.xlsxfile,
        res.html,
        DEFAULT_SUBSYS,
        all_subsys )       
    CACHED_RESULTS[allsubsys] = resp
    to_session( resp )
    obs[]= Progress( settings.uuid, "end", -99, -99, -99, -99 )
end
  
struct SubsysAndSession{T}
    subsys  :: AllLASubsys{T}
    session :: GenieSession.Session
end
  
# this many simultaneous (sp) runs
#
const NUM_HANDLERS = 2
#
# This number of submissions
#
const QSIZE = 32

IN_QUEUE = Channel{SubsysAndSession}(QSIZE)

function submit_job()
    systype = systype_from_session()
    session = GenieSession.session() #  :: GenieSession.Session 
    subsys = subsys_from_payload()
    allsubsys = get_params_from_session()
    if subsys.systype == sys_civil 
        allsubsys.civil = subsys
    else 
        allsubsys.aa = subsys
    end
    GenieSession.set!( session, :allsubsys, allsubsys )    
    @info "submit_job facs=" facs
    if ! haskey( CACHED_RESULTS, allsubsys )    
        put!( IN_QUEUE, allsubsys )
        qp = ( phase="queued" ,completed=0, size=0 )
        GenieSession.set!( session, :progress, qp )    
        return ( response=has_progress, data=qp ) |> json
    else
        GenieSession.set!( session, :progress, (phase="end",completed=0, size=0 ))
        resp = CACHED_RESULTS[allsubsys]
        return ( response=output_ready, data=OneResponse( systype, resp)) |> json      
    end
end

"""
"""
function grab_runs_from_queue()
    while true
        params = take!( IN_QUEUE )
        do_session_run( params.session, params.subsys ) 
    end
end

#
# Run the job queues
#
for i in 1:NUM_HANDLERS # start n tasks to process requests in parallel
    @info "starting handler $i" 
    errormonitor(@async grab_runs_from_queue())
end

