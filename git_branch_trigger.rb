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
# This trigger will not fire the first time it is evaluated for a project.  It
# will only record the current list of branches for future reference.
# Thereafter, it will update the saved list of branches each time it is
# evaluated.
#
# When this trigger fires, it will notify the project with
# @:branch_list_changed@.  Otherwise, it will notify the project with
# @:branch_list_unchanged@.
class GitBranchTrigger
  def initialize(project, git_url)
    @project = project
    @git_url = git_url
  end

  def build_necessary?(reasons)
    branch_list_file = File.join(@project.path, "branch.list")

    # Retrieve the old list of branches if there is one.
    begin
      old_branch_list = File.readlines(branch_list_file).map(&:chomp)
    rescue Errno::ENOENT
      # Ignored... First run for this project.
    end

    # Retrieve the current list of branches.
    new_branch_list = IO.popen("git ls-remote --heads #{@git_url}") do |git|
      git.readlines
    end
    new_branch_list.map! { |l| l.chomp.split(/\s+/)[1] }
    new_branch_list.sort!
    # Save the list.
    File.open(branch_list_file, "w") { |f| f.puts new_branch_list }

    # Trigger the build only if there is a change in the branch list.
    if old_branch_list.nil? || old_branch_list == new_branch_list
      @project.notify :branch_list_unchanged
      false
    else
      @project.notify :branch_list_changed
      true
    end
  end
end