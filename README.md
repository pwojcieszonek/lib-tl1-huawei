# Lib::TL1::Huawei

A Ruby library for building commands and parsing TL1 NBI responses from Huawei iManager U2000.
It extends `lib-tl1`, using its fields and TL1 frame parser to read Huawei metadata
and tables. It provides a subset of queries for devices, GPON/ONT, GEM, profiles,
optical parameters, statistics, IP/WAN, VLAN and VoIP, as well as session commands.

The library does not establish TCP/TLS connections, send commands, maintain sessions
or assemble multipart responses. These are the responsibility of the application using the gem.

## Installation

Ruby `>= 3.4.0` is required. Older Ruby versions are no longer supported.
Add the following to your application's `Gemfile`:

```gemfile
gem 'lib-tl1-huawei'
```

Then run `bundle install`. The gem depends on `lib-tl1 ~> 0.1.2`
and `ostruct >= 0.1.0, < 1.0`; Bundler installs them automatically.
The entry point is `require 'lib/tl1/huawei'`, and the namespace is `Lib::TL1::Huawei`.

## Building a command

This example builds an `LST-ONTDETAIL` command to query details for ONT 3 on
port 2, slot 8, frame 0 of device 1. `CTAG` is a request identifier that lets the
application match a response to its command. Set it with `message.ctag` before
calling `to_s` to produce the TL1 command string.

```ruby
require 'lib/tl1/huawei'

message = Lib::TL1::Huawei::Message::LstOntDetail.new(
  did: 1, frame_number: 0, slot_number: 8, port_number: 2, ont_id: 3
)
message.ctag = 101
puts message.to_s
# LST-ONTDETAIL::DID=1,FN=0,SN=8,PN=2,ONTID=3:101::;
```

`DID` is the device identifier in U2000. `DEV` means the device name by default,
but the `DevMean`/`DEVMEAN` setting can change its meaning to the IP address.
Choose `did:` or `dev:` according to the NBI configuration and the command's requirements.
The library does not read this configuration or validate the address against a device.

| Ruby argument | TL1 field | Meaning |
| --- | --- | --- |
| `frame_number:` | `FN` | OLT frame/shelf number |
| `slot_number:` | `SN` | Slot number |
| `port_number:` | `PN` | Port number |
| `ont_id:` | `ONTID` | ONT identifier on the port |
| `ont_name:` | `NAME` | ONT name, together with `DID` or `DEV` |
| `ont_alias:` | `ALIAS` | Alternative ONT addressing by alias |

For `LstOntDetail`, choose the ONT coordinates, a name with a device, or an alias alone;
do not combine all addressing variants. Available arguments depend on the constructor.
For example, `LstOnt` uses `onu_name:` for `NAME` and supports `ont_sn:` (`ONTSN`)
and `ont_pwd:` (`PWD`); `LstOntDbaProf` also maps `ont_pwd:` to `PWD`.
`LstGponAutoFind` sends `LST-GPONONTAUTOFIND` and accepts a serial number or an OLT location.
`LstGponNniPort` is a separate query for NNI ports with optional `SHOWOPTION`.
For example, `LstGponNniPort` supports `show_option: [:PSTAT]`;
the allowed `SHOWOPTION` fields differ between commands.

## Reading responses and errors

Run the following examples from the repository directory, for example with `bundle exec ruby`.
The files in `spec/fixtures/huawei` are synthetic: they contain no subscriber data and
are not device session recordings. Fixtures and tests are not packaged in the installed gem.

```ruby
require 'lib/tl1/huawei'

raw = File.binread('spec/fixtures/huawei/one_record.tl1')
output = Lib::TL1::Huawei::Message::Output.parse(raw, encoding: 'UTF-8')
puts output.ont_id             # 1
puts output.first.name         # Office west
puts output.first.rx_power     # --
puts output.to_h[:blktotal]     # 1
```

`Output.parse` accepts one complete response. `response` is an array of
`Response` records based on `OpenStruct`; `first`, `each`, `map`, `[]` and `size` provide
collection operations. Column names are converted to lowercase, and records also support
snake_case names: `ontid` and `ont_id` read the same field.
Record getters are delegated directly from `Output` only when
`blktotal == 1` and `response.size == 1`. Use the collection for empty results or results
with multiple records; `respond_to?` follows the same delegation rule.

`blktag` is the packet number, `blkcount` is the number of records in that packet, and
`blktotal` is the total number of records, not packets. `to_h` returns the header,
`en`, `endesc`, counters, title and an array of hashes in `:response`. Field values remain
strings without unit conversion; `--` remains `--`, and an empty table cell remains an empty string.

```ruby
require 'lib/tl1/huawei'

begin
  raw = File.binread('spec/fixtures/huawei/error.tl1')
  Lib::TL1::Huawei::Message::Output.parse(raw, encoding: 'UTF-8')
rescue Lib::TL1::Huawei::StandardError => error
  puts "#{error.error_number}: #{error.message}"
  # 123: Example device error.
end
```

A nonzero `EN` identifies a Huawei error; `ENDESC` supplies its description.
Do not compare the description with a literal success message. Frame syntax errors can also
come from the `lib-tl1` parser and may raise exceptions other than `Lib::TL1::Huawei::StandardError`.

## Encoding and API compatibility

The default `encoding: nil` preserves the bytes and encoding of the input `String`.
For `File.binread`, this means `ASCII-8BIT`, without guessing the server's encoding.
An explicit `encoding: 'UTF-8'`, `'GBK'` or `'ISO-8859-1'` interprets a copy of the input
bytes in the specified encoding and decodes it to UTF-8. Match it to the U2000 `CharSet`
configuration. Invalid data raises an exception; the parser does not replace characters.
Repeated reads and `to_h` do not change the source data or the encoding of record values.
`to_h` no longer forces conversion from ISO-8859-1.

`reverse` returns a reversed copy of the collection without changing its order.
The broken delegator with the misspelled name `revers` has been removed; replace calls to it
with `reverse`. `LstDev#dev_type` reflects the constructor argument, and `show_option`
and the retained alias `showoption` return the same list of options.

`LstOntEthVlanSwitchPair` sends `LST-ONTETHVLANSWTICHPAIR`, with the intentional
spelling `SWTICHPAIR`. It replaces the previously sent
`LST-ONTETHVLANSWITCHPAIR`. The `ont_port_type:` argument is serialized in uppercase
(the default `:eth` produces `ETH`); `nil` omits the field, and the getter preserves the supplied argument.

Tests use synthetic fixtures and do not establish compatibility with a live U2000 system.
The library implements a subset of U2000 commands and addressing variants; the class list is in
the [message loader](lib/lib/tl1/huawei/message.rb), and the maintained signatures are in
the [RBS signatures](sig/lib/tl1/), whose file layout mirrors `lib/lib/tl1/`.

## Development

Select a supported Ruby environment with RVM; `.ruby-version` specifies `3.4`,
and `.ruby-gemset` specifies `lib-tl1-huawei`. Use this gemset name when selecting another
supported Ruby version as well, for example `rvm use 4.0.2@lib-tl1-huawei --create`.
Install dependencies, including the `development` group, in the selected gemset and
run the local checks:

```sh
bundle check
bundle install
bundle exec rake
```

`bundle install` is only needed when `bundle check` reports missing dependencies.
The default Rake task runs RuboCop followed by RSpec. Use `bundle exec rake rubocop`
for lint only or `bundle exec rake spec` for tests only.
RuboCop settings live in `.rubocop.yml`, without an offense baseline.
The configuration preserves named TL1 parameters and the `gb`/`cc` protocol keywords,
counts multiline data literals as one expression for method length, and excludes
declarative RSpec `describe` groups from block length checks. Individual examples
and helpers retain the default limits. `Response` alone is exempt from
`Style/OpenStructUse` to preserve its public dynamic, mutable record API; all
other checks still apply to it. Fix new offenses in code instead of generating
exclusions; any rule adjustment needs an explicit design or compatibility reason.
The tests do not connect to U2000; they also execute the Ruby examples in this README.
CI runs RuboCop on Ruby 3.4 and tests on Ruby 3.4 and 4.0 for pull requests,
pushes to `master` and `v*` tags. Both checks must pass before release tag preparation.

## Publishing

When a push to `master` changes `Lib::TL1::Huawei::VERSION` in
`lib/lib/tl1/huawei/version.rb`, the workflow runs the tests and creates a matching
`v<VERSION>` tag (for example, `v0.1.9`). It compares the versions before and after
the entire push, including pushes containing multiple commits. Unchanged versions,
initial branch creation and existing tags do not trigger an automatic release.
Existing tags are never moved.

Only a newly created tag enables the build and publication using
[RubyGems Trusted Publishing](https://guides.rubygems.org/trusted-publishing/).
Tags created by the workflow use `GITHUB_TOKEN`, which
[does not trigger another push workflow](https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/trigger-a-workflow#triggering-a-workflow-from-a-workflow).
The dependent publishing job therefore runs in the same workflow after tag creation,
without a personal access token. A new `v*` tag pushed manually also runs the tests
and publishes, provided its name matches the version at the tagged commit.
Deleting or updating an existing tag does not publish a gem.

The workflow exchanges a GitHub Actions OIDC token for short-lived RubyGems credentials
through the official
[`configure-rubygems-credentials` action](https://github.com/rubygems/configure-rubygems-credentials).
Only the publishing job has `id-token: write`; it uses the `release` environment.
The tag preparation job has `contents: write`; repository rules must allow
`GITHUB_TOKEN` to create `v*` tags.

Before the first publication through this workflow, create the GitHub environment `release`
and register a trusted publisher for `lib-tl1-huawei` on RubyGems.org with these values:

| Setting | Value |
| --- | --- |
| Repository owner | `pwojcieszonek` |
| Repository name | `lib-tl1-huawei` |
| Workflow filename | `main.yml` |
| Environment | `release` |

The workflow filename is the basename of `.github/workflows/main.yml`.
The RubyGems and GitHub environment names must match. No `RUBYGEMS_AUTH_TOKEN` secret
is required by this workflow.
If the `release` environment restricts deployment branches or tags, allow both
`master` (automatic tags) and `v*` tags (manual tag pushes). Required environment
reviewers, if configured, still need to approve publication.

Set a new, unpublished version in `lib/lib/tl1/huawei/version.rb` before pushing a release
to `master`; RubyGems rejects attempts to publish an existing version again.
If publication fails after automatic tag creation, use GitHub Actions' **Re-run failed jobs**
to retry publication with the existing tag output. Re-running all jobs finds the
existing tag and skips the automatic release.
Local tests and `gem build lib-tl1-huawei.gemspec` do not publish the gem.

This project is available under the [MIT license](LICENSE.txt).
