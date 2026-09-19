# frozen_string_literal: true

require 'open3'
require 'rbconfig'

RSpec.describe 'README examples' do
  repository_root = File.expand_path('../../..', __dir__)
  readme = File.read(File.join(repository_root, 'README.md'), encoding: 'UTF-8')
  examples = readme.scan(/^```ruby[ \t]*\n(.*?)^```[ \t]*$/m).flatten
  expected_outputs = [
    "LST-ONTDETAIL::DID=1,FN=0,SN=8,PN=2,ONTID=3:101::;\n",
    "1\nOffice west\n--\n1\n",
    "123: Example device error.\n"
  ]

  it 'covers every executable Ruby example in the documentation' do
    expect(examples.size).to eq(expected_outputs.size)
  end

  expected_outputs.each_with_index do |expected, index|
    it "runs example #{index + 1} using local synthetic data" do
      stdout, stderr, status = Open3.capture3(
        RbConfig.ruby, '-I', File.join(repository_root, 'lib'), '-e', examples.fetch(index),
        chdir: repository_root
      )

      expect(status.success?).to be(true), stderr
      expect(stdout).to eq(expected)
    end
  end
end
