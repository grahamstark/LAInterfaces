
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
    return if systype == sys_civil
        OneResponse( systype, resp.xlsxfile.civil, resp.html.civil, resp.default_params.civil, resp.params.civil )
    else
        OneResponse( systype, resp.xlsxfile.aa, resp.html.aa, resp.default_params.aa, resp.params.aa )
    end
end

function to_session( session, res :: CompleteResponse )
    # GenieSession.set!( session, :systype, res.systype )
    GenieSession.set!( session, :xlsxfile, res.xlsxfile )
    GenieSession.set!( session, :html, res.html )
    GenieSession.set!( session, :allsubsys, res.params )
end

function from_session(session)::CompleteResponse 
    if( GenieSession.isset( session, :html ))
        return CompleteResponse(
            GenieSession.get( session, :xlsxfile ),
            GenieSession.get( session, :html),
            GenieSession.get( session, :allsubsys ),
            DEFAULT_SUBSYS )
    else
        resp = deepcopy( DEFAULT_COMPLETE_RESPONSE )
        to_session( session, resp )
        return resp
    end
end

const CACHED_RESULTS = LRU{AllLASubsys,CompleteResponse}(maxsize=25)

function systype_from_session( session ::GenieSession.Session )
    systype = sys_civil
    if( GenieSession.isset( session, :systype ))
        systype = GenieSession.get( session, :systype )
    else
        GenieSession.set!( session, :systype, systype )
    end
    return systype
end

function getprogress() 
    sess = GenieSession.session()
    systype = systype_from_session(sess)
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
  
function session_obs(
    session  :: GenieSession.Session,
    settings :: Settings )::Observable
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
  
function get_params_from_session(session::GenieSession.Session)::AllLASubsys
    systype = systype_from_session( session )
    allsubsys = nothing
    if( GenieSession.isset( session, :allsubsys ))
        allsubsys = GenieSession.get( session, :allsubsys )
    else
        allsubsys = AllLASubsys( DEFAULT_PARAMS.legalaid )
        GenieSession.set!( session, :allsubsys, allsubsys )
    end
    return allsubsys
end

function reset()
    session = GenieSession.session()
    systype = systype_from_session(session)
    resp = deepcopy( DEFAULT_COMPLETE_RESPONSE )
    to_session( session, resp )
    return ( response=output_ready, data = OneResponse( systype, resp)) |> json
end

function switch_system()
    session = GenieSession.session()
    systype = systype_from_session(session)
    systype = systype == sys_civil ? sys_aa : sys_civil
    GenieSession.set!( session, :systype, systype )
    resp = from_session(session)
    return ( response=output_ready, data = OneResponse( systype, resp)) |> json
end

"""
return output for the 
"""
function get_output() 
    session = GenieSession.session()
    systype = systype_from_session(session)
    resp = from_session(session)
    return ( response=output_ready, data = OneResponse( systype, resp)) |> json
end

"""
Execute a run from the queue.
"""
function do_session_run( session::Session, allsubsys :: AllLASubsys )
    systype = systype_from_session( session )
    activesubsys = systype == sys_civil ? allsubsys.civil : allsubsys.aa    
    settings = make_default_settings()  
    sys2 = deepcopy( DEFAULT_PARAMS )
    sys2.legalaid.civil = map_sys_from_subsys( allsubsys.civil )
    sys2.legalaid.aa = map_sys_from_subsys( allsubsys.aa )
    map_settings_from_subsys!( settings, activesubsys )
    @info "dorun entered activesubsys is " activesubsys
    obs = session_obs( session, settings )
    res = do_la_run( settings, DEFAULT_PARAMS, sys2, obs )
    # output = (; html, xlsxfile, params=allsubsys, defaults=default_subsys )
    obs[]=Progress( settings.uuid, "results-generation", 0, 0, 0, 0 )
    resp = CompleteResponse(
        res.xlsxfile,
        res.html,
        DEFAULT_SUBSYS,
        allsubsys )       
    CACHED_RESULTS[allsubsys] = resp
    to_session( session, resp )
    obs[]= Progress( settings.uuid, "end", -99, -99, -99, -99 )
end
  
#=
 Implement a job queue. 
 see: https://docs.julialang.org/en/v1/manual/asynchronous-programming/
 for how to set this up.
 !!! NOTE !!! You need __precompile__(false) with Julia 10.x in the 
 module header for this to work.
=# 

#
# this many simultaneous (sp) runs
#
const NUM_HANDLERS = 4
#
# This number of submissions
#
const QSIZE = 32
struct SubsysAndSession{T}
  subsys  :: AllLASubsys{T}
  session :: GenieSession.Session
end

IN_QUEUE = Channel{SubsysAndSession{Float64}}(QSIZE) # 

function submit_job()
    session = GenieSession.session() 
    systype = systype_from_session(session)
    subsys = subsys_from_payload()
    allsubsys = get_params_from_session(session)
    if subsys.systype == sys_civil 
        allsubsys.civil = subsys
    else 
        allsubsys.aa = subsys
    end
    GenieSession.set!( session, :allsubsys, allsubsys )    
    @info "submit_job subsys=" subsys
    sas = SubsysAndSession(allsubsys,session)
    if ! haskey( CACHED_RESULTS, sas )    
        put!( IN_QUEUE, sas )
        qp = ( phase="queued" ,completed=0, size=0 )
        GenieSession.set!( session, :progress, qp )    
        return ( response=has_progress, data=qp ) |> json
    else
        GenieSession.set!( session, :progress, (phase="end",completed=0, size=0 ))
        resp = CACHED_RESULTS[sas]
        return ( response=output_ready, data=OneResponse( systype, resp)) |> json      
    end
end

function grab_runs_from_queue()
    while true
        onejob = take!( IN_QUEUE )
        println( "rtrr")
        do_session_run( onejob.session, onejob.subsys ) 
    end
end

#
# Run the job queues
#
for i in 1:NUM_HANDLERS # start n tasks to process requests in parallel
  @info "starting handler $i"   
  errormonitor( @async grab_runs_from_queue())
end