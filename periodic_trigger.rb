# This is a trigger that will fire whenever the time since the last build of a
# project exceeds a given period.
#
# Add this trigger using your @cruise_config.rb@ file:
#
# <pre><code>Project.configure do |project|
#   ...
#   project.triggered_by PeriodicTrigger.new(project, 5.minutes)
#   ...
# end</code></pre>
class PeriodicTrigger
  def initialize(triggered_project, period)
    @triggered_project = triggered_project
    @period = period
  end

  def build_necessary?(reasons)
    last_build = @triggered_project.last_build
    if last_build && Time.now - last_build.time > @period
      reasons << "Wait period expired"
      true
    else
      false
    end
  end
end
