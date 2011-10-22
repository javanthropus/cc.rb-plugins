# This is a trigger that will fire whenever the list of branches in a git
# repository changes.  It uses @git ls-remote@ to query the repository, so any
# valid URL for git will work.
#
# This trigger assumes that no interactive authentication is required to access
# the repository.  Look into configuring SSH keys, a @~/.netrc@ file, or some
# other credential store as necessary.
#
# Add this trigger using your @cruise_config.rb@ file:
#
# <pre><code>Project.configure do |project|
#   ...
#   project.triggered_by GitBranchTrigger.new(
#     project,
#     "http://example.com/git/example.git"
#   )
#   ...
# end</code></pre>
#
# This trigger will not fire the first time it is evaluated after the builder
# starts.  It will only record the current list of branches for future
# reference.  Thereafter, it will fire when changes are seen.
class GitBranchTrigger
  def initialize(project, git_url)
    @project = project
    @git_url = git_url
    @branch_list = nil
  end

  def build_necessary?(reasons)
    # Retrieve the current list of branches.
    new_branch_list = IO.popen("git ls-remote --heads #{@git_url} 2>&1") do |git|
      git.readlines
    end

    # Do not trigger if there was an error retrieving the branch list.
    unless $?.success?
      CruiseControl::Log.event("Error querying branches in git repository `#{@git_url}':\n#{new_branch_list.join}", :error)
      return false
    end

    # Parse out the branch names and sort the list.
    new_branch_list.map! { |l| l.chomp.split(/\s+/)[1] }
    new_branch_list.sort!

    # Update the saved branch list with the current branches.
    old_branch_list = @branch_list
    @branch_list = new_branch_list

    # Trigger the build only if there is a change in the branch list.
    if old_branch_list.nil? || old_branch_list == new_branch_list
      false
    else
      reasons << "List of branches at #{@git_url} changed"
      true
    end
  end
end
