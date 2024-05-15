
# ==== Queue stuff

function getprogress() 
    sess = GenieSession.session()
    @info "getprogress entered"
    progress = ( phase="missing", completed = 0, size=0 )
    if( GenieSession.isset( sess, :progress ))
        @info "getprogress: has progress"
        progress = GenieSession.get( sess, :progress )
    else
        @info "getprogress: no progress"
        GenieSession.set!( sess, :progress, progress )
    end
    ( response=has_progress, data=progress) |> json
  end


"""

"""
function get_output_from_cache() # removed bacause json doesn't like ::Union{NamedTuple,String}
    facs = factorsfromsession()
    @info "getoutput facs=" facs
    nvc = NonVariableFacts( facs )
    @info "getoutput; nvc = " nvc 
    @info "getoutput keys are " keys(CACHED_RESULTS)
    if haskey(CACHED_RESULTS, nvc )
      @info "got results from CACHED_RESULTS " 
      output = CACHED_RESULTS[nvc]
      return ( response=output_ready, data=output)
    end
    @info "responding with bad_request" 
    return( response=bad_request, data="" )  
end 

  
  """
  return output for the 
  """
function getoutput() 
    return get_output_from_cache()|> json 
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
  
function screen_obs()::Observable
    obs = Observable( Progress(settings.uuid, "",0,0,0,0))
    completed = 0
    of = on(obs) do p
        if p.phase == "do-one-run-end"
        completed = 0
        end
        completed += p.step
        @info "monitor completed=$completed p = $(p)"
    end
    return obs
end
  
"""
Execute a run from the queue.
"""
function dorun( session::Session, subsys :: LASubsys )
settings = make_default_settings()  
@info "dorun entered subsys is " subsys
obs = session_obs(session)
#=
results = do_one_conjoint_run!( facs, obs; settings = settings )  
exres = calc_examples( results.sys1, results.sys2, results.settings ) 
obs[]=Progress( settings.uuid, "results-generation", 0, 0, 0, 0 )   
output = results_to_html_conjoint( settings, ( results..., examples=exres  ))  
GenieSession.set!( :facs, facs ) # save again since poverty, etc. is overwritten in doonerun!
save_output_to_cache( facs, output )
=#
obs[]= Progress( settings.uuid, "end", -99, -99, -99, -99 )
end
  
function submit_job()
    session = GenieSession.session() #  :: GenieSession.Session 
    facs = facsfrompayload( rawpayload() )
    GenieSession.set!( session, :facs, facs )
    
    @info "submit_job facs=" facs
    if ! haskey( CACHED_RESULTS, NonVariableFacts(facs))    
    put!( IN_QUEUE, FactorAndSession( facs, session ))
    qp = ( phase="queued" ,completed=0, size=0 )
    GenieSession.set!( session, :progress, qp )
    return ( response=has_progress, data=qp ) |> json
    else
    GenieSession.set!( session, :progress, (phase="end",completed=0, size=0 ))
    return ( response=output_ready, data=get_output_from_cache()) |> json      
    end
end
  
struct SubsysAndSession{T}
    subsys     :: LASubsys{T}
    session  :: GenieSession.Session
end
  
# this many simultaneous (sp) runs
#
const NUM_HANDLERS = 4
#
# This number of submissions
#
const QSIZE = 32

IN_QUEUE = Channel{SubsysAndSession}(QSIZE)

"""
"""
function grab_runs_from_queue()
    while true
        params = take!( IN_QUEUE )
        dorun( params.session, params.subsys ) 
    end
end


#
# Run the job queues
#
for i in 1:NUM_HANDLERS # start n tasks to process requests in parallel
    @info "starting handler $i" 
    errormonitor(@async grab_runs_from_queue())
end

