# frozen_string_literal: true

require 'fileutils'
require 'open3'
require 'tmpdir'
require 'yaml'

RSpec.describe 'Release workflow tag selection' do
  let(:workflow_path) { File.expand_path('../.github/workflows/main.yml', __dir__) }
  let(:release_script) do
    workflow = YAML.safe_load_file(workflow_path)
    workflow.fetch('jobs').fetch('release_tag').fetch('steps')
            .find { |step| step['id'] == 'release' }.fetch('run')
  end
  let(:subprocess_env) do
    {
      'BUNDLE_GEMFILE' => nil,
      'BUNDLE_BIN_PATH' => nil,
      'RUBYOPT' => nil,
      'GIT_DIR' => nil,
      'GIT_WORK_TREE' => nil,
      'GIT_INDEX_FILE' => nil,
      'GIT_CONFIG_GLOBAL' => File::NULL,
      'GIT_CONFIG_NOSYSTEM' => '1'
    }
  end

  around do |example|
    Dir.mktmpdir('huawei-release-workflow-') do |directory|
      @work = File.join(directory, 'work')
      @origin = File.join(directory, 'origin.git')
      @output = File.join(directory, 'github-output')
      FileUtils.mkdir_p(@work)
      git('init', '--bare', @origin)
      git('init', '--initial-branch=master')
      git('config', 'user.name', 'Workflow test')
      git('config', 'user.email', 'workflow@example.invalid')
      git('remote', 'add', 'origin', @origin)
      @before = commit_version('0.1.8')
      git('push', 'origin', 'master')

      example.run
    end
  end

  def git(*arguments)
    stdout, stderr, status = Open3.capture3(subprocess_env, 'git', *arguments, chdir: @work)
    raise "git #{arguments.join(' ')} failed: #{stderr}" unless status.success?

    stdout.strip
  end

  def commit_file(path, content)
    destination = File.join(@work, path)
    FileUtils.mkdir_p(File.dirname(destination))
    File.write(destination, content)
    git('add', '--', path)
    git('commit', '-m', "Update #{path}")
    git('rev-parse', 'HEAD')
  end

  def commit_version(version)
    commit_file('lib/lib/tl1/huawei/version.rb', <<~RUBY)
      module Lib
        module TL1
          module Huawei
            VERSION = '#{version}'
          end
        end
      end
    RUBY
  end

  def release_environment(before_sha:, sha:, ref_type:, ref_name:)
    subprocess_env.merge(
      'BEFORE_SHA' => before_sha,
      'GITHUB_SHA' => sha,
      'GITHUB_REF_TYPE' => ref_type,
      'GITHUB_REF_NAME' => ref_name,
      'GITHUB_OUTPUT' => @output
    )
  end

  def run_release(before_sha: @before, sha: git('rev-parse', 'HEAD'), ref_type: 'branch', ref_name: 'master')
    File.write(@output, '')
    environment = release_environment(before_sha: before_sha, sha: sha, ref_type: ref_type, ref_name: ref_name)
    @stdout, @stderr, status = Open3.capture3(
      environment, 'bash', '-e', '-o', 'pipefail', '-c', release_script, chdir: @work
    )
    status
  end

  def release_output
    File.read(@output)
  end

  def remote_tags
    git('--git-dir', @origin, 'for-each-ref', '--format=%(refname:short) %(objectname)', 'refs/tags')
  end

  it 'creates a matching tag at the event commit and selects it for publication' do
    release_sha = commit_version('0.1.9')
    commit_file('README.md', 'A later checkout commit with the same version.')

    expect(run_release(sha: release_sha)).to be_success, "#{@stdout}\n#{@stderr}"
    expect(release_output).to eq("tag=v0.1.9\n")
    expect(remote_tags).to eq("v0.1.9 #{release_sha}")
  end

  it 'does not release an unchanged version' do
    commit_file('README.md', 'A documentation change.')

    expect(run_release).to be_success, "#{@stdout}\n#{@stderr}"
    expect(release_output).to be_empty
    expect(remote_tags).to be_empty
  end

  it 'does not release a formatting-only change to the version file' do
    path = 'lib/lib/tl1/huawei/version.rb'
    commit_file(path, "# frozen_string_literal: true\n\n#{File.read(File.join(@work, path))}")

    expect(run_release).to be_success, "#{@stdout}\n#{@stderr}"
    expect(release_output).to be_empty
    expect(remote_tags).to be_empty
  end

  it 'compares the version with the previous push revision for a multi-commit push' do
    commit_version('0.1.9')
    release_sha = commit_file('README.md', 'The final commit in the push does not change the version.')

    expect(run_release).to be_success, "#{@stdout}\n#{@stderr}"
    expect(release_output).to eq("tag=v0.1.9\n")
    expect(remote_tags).to eq("v0.1.9 #{release_sha}")
  end

  it 'leaves an existing tag unchanged and does not select it for automatic publication' do
    git('tag', 'v0.1.9', @before)
    git('push', 'origin', 'refs/tags/v0.1.9')
    commit_version('0.1.9')

    expect(run_release).to be_success, "#{@stdout}\n#{@stderr}"
    expect(release_output).to be_empty
    expect(git('rev-parse', 'refs/tags/v0.1.9')).to eq(@before)
    expect(remote_tags).to eq("v0.1.9 #{@before}")
  end

  it 'selects a matching manually pushed tag for publication' do
    release_sha = commit_version('0.1.9')
    git('tag', 'v0.1.9')
    git('push', 'origin', 'refs/tags/v0.1.9')

    expect(run_release(ref_type: 'tag', ref_name: 'v0.1.9')).to be_success, "#{@stdout}\n#{@stderr}"
    expect(release_output).to eq("tag=v0.1.9\n")
    expect(remote_tags).to eq("v0.1.9 #{release_sha}")
  end

  it 'rejects a manually pushed tag that does not match the version' do
    release_sha = commit_version('0.1.9')
    git('tag', 'v0.2.0')
    git('push', 'origin', 'refs/tags/v0.2.0')

    expect(run_release(ref_type: 'tag', ref_name: 'v0.2.0')).not_to be_success
    expect(@stdout).to include('does not match version')
    expect(release_output).to be_empty
    expect(remote_tags).to eq("v0.2.0 #{release_sha}")
  end

  it 'does not select a tag for publication when the remote rejects its push' do
    commit_version('0.1.9')
    hook = File.join(@origin, 'hooks', 'pre-receive')
    File.write(hook, "#!/bin/sh\nexit 1\n")
    File.chmod(0o755, hook)

    expect(run_release).not_to be_success
    expect(release_output).to be_empty
    expect(remote_tags).to be_empty
  end

  it 'does not publish when another run has already pushed the same tag at the same commit' do
    release_sha = commit_version('0.1.9')
    git('push', 'origin', 'master')
    git('--git-dir', @origin, 'tag', 'v0.1.9', release_sha)

    expect(run_release).to be_success, "#{@stdout}\n#{@stderr}"
    expect(release_output).to be_empty
    expect(remote_tags).to eq("v0.1.9 #{release_sha}")
  end

  it 'skips automatic publication when the branch has no previous revision' do
    commit_version('0.1.9')

    expect(run_release(before_sha: '0' * 40)).to be_success, "#{@stdout}\n#{@stderr}"
    expect(release_output).to be_empty
    expect(remote_tags).to be_empty
  end
end
