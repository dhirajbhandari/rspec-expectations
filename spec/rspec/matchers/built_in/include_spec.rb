require 'uri'

describe "#include matcher" do
  it "is diffable" do
    expect(include("a")).to be_diffable
  end

  describe "expect(...).to include(with_one_arg)" do
    it_behaves_like "an RSpec matcher", :valid_value => [1, 2], :invalid_value => [1] do
      let(:matcher) { include(2) }
    end

    context "for a string target" do
      it "passes if target includes expected" do
        expect("abc").to include("a")
      end

      it "fails if target does not include expected" do
        expect {
          expect("abc").to include("d")
        }.to fail_matching("expected \"abc\" to include \"d\"")
      end

      it "includes a diff when actual is multiline" do
        expect {
          expect("abc\ndef").to include("g")
        }.to fail_matching("expected \"abc\\ndef\" to include \"g\"\nDiff")
      end

      it "includes a diff when actual is multiline and there are multiple expecteds" do
        expect {
          expect("abc\ndef").to include("g", "h")
        }.to fail_matching("expected \"abc\\ndef\" to include \"g\" and \"h\"\nDiff")
      end
    end

    context "for an array target" do
      it "passes if target includes expected" do
        expect([1,2,3]).to include(3)
      end

      it "fails if target does not include expected" do
        expect {
          expect([1,2,3]).to include(4)
        }.to fail_matching("expected [1, 2, 3] to include 4")
      end

      it 'fails when given differing null doubles' do
        dbl_1 = double.as_null_object
        dbl_2 = double.as_null_object

        expect {
          expect([dbl_1]).to include(dbl_2)
        }.to fail_matching("expected [#{dbl_1.inspect}] to include")
      end

      it 'passes when given the same null double' do
        dbl = double.as_null_object
        expect([dbl]).to include(dbl)
      end
    end

    context "for a hash target" do
      it 'passes if target has the expected as a key' do
        expect({:key => 'value'}).to include(:key)
      end

      it "fails if target does not include expected" do
        expect {
          expect({:key => 'value'}).to include(:other)
        }.to fail_matching(%Q|expected {:key => "value"} to include :other|)
      end

      it "fails if target doesn't have a key and we expect nil" do
        expect {
          expect({}).to include(:something => nil)
        }.to fail_matching(%Q|expected {} to include {:something => nil}|)
      end

      it 'works even when an entry in the hash overrides #send' do
        hash = { :key => 'value' }
        def hash.send; :sent; end
        expect(hash).to include(hash)
      end

      context 'that overrides #send' do
        it 'still works' do
          array = [1, 2]
          def array.send; :sent; end

          expect(array).to include(*array)
        end
      end
    end
  end

  describe "expect(...).to include(with, multiple, args)" do
    it "has a description" do
      matcher = include("a")
      expect(matcher.description).to eq("include \"a\"")
    end
    context "for a string target" do
      it "passes if target includes all items" do
        expect("a string").to include("str", "a")
      end

      it "fails if target does not include any one of the items" do
        expect {
          expect("a string").to include("str", "a", "foo")
        }.to fail_matching(%Q{expected "a string" to include "str", "a", and "foo"})
      end
    end

    context "for an array target" do
      it "passes if target includes all items" do
        expect([1,2,3]).to include(1,2,3)
      end

      it "fails if target does not include any one of the items" do
        expect {
          expect([1,2,3]).to include(1,2,4)
        }.to fail_matching("expected [1, 2, 3] to include 1, 2, and 4")
      end
    end

    context "for a hash target" do
      it 'passes if target includes all items as keys' do
        expect({:key => 'value', :other => 'value'}).to include(:key, :other)
      end

      it 'fails if target is missing any item as a key' do
        expect {
          expect({:key => 'value'}).to include(:key, :other)
        }.to fail_matching(%Q|expected {:key => "value"} to include :key and :other|)
      end
    end
  end

  describe "expect(...).not_to include(expected)" do
    context "for a string target" do
      it "passes if target does not include expected" do
        expect("abc").not_to include("d")
      end

      it "fails if target includes expected" do
        expect {
          expect("abc").not_to include("c")
        }.to fail_with("expected \"abc\" not to include \"c\"")
      end
    end

    context "for an array target" do
      it "passes if target does not include expected" do
        expect([1,2,3]).not_to include(4)
      end

      it "fails if target includes expected" do
        expect {
          expect([1,2,3]).not_to include(3)
        }.to fail_with("expected [1, 2, 3] not to include 3")
      end

      it 'passes when given differing null doubles' do
        expect([double.as_null_object]).not_to include(double.as_null_object)
      end

      it 'fails when given the same null double' do
        dbl = double.as_null_object

        expect {
          expect([dbl]).not_to include(dbl)
        }.to fail_matching("expected [#{dbl.inspect}] not to include")
      end
    end

    context "for a hash target" do
      it 'passes if target does not have the expected as a key' do
        expect({:other => 'value'}).not_to include(:key)
      end

      it "fails if target includes expected key" do
        expect {
          expect({:key => 'value'}).not_to include(:key)
        }.to fail_matching(%Q|expected {:key => "value"} not to include :key|)
      end
    end

  end

  describe "expect(...).not_to include(with, multiple, args)" do
    context "for a string target" do
      it "passes if the target does not include any of the expected" do
        expect("abc").not_to include("d", "e", "f")
      end

      it "fails if the target includes all of the expected" do
        expect {
          expect("abc").not_to include("c", "a")
        }.to fail_with('expected "abc" not to include "c" and "a"')
      end

      it "fails if the target includes some (but not all) of the expected" do
        expect {
          expect("abc").not_to include("d", "a")
        }.to fail_with(%q{expected "abc" not to include "d" and "a"})
      end
    end

    context "for a hash target" do
      it "passes if it does not include any of the expected keys" do
        expect({ :a => 1, :b => 2 }).not_to include(:c, :d)
      end

      it "fails if the target includes all of the expected keys" do
        expect {
          expect({ :a => 1, :b => 2 }).not_to include(:a, :b)
        }.to fail_matching(%r|expected #{hash_inspect :a => 1, :b => 2} not to include :a and :b|)
      end

      it "fails if the target includes some (but not all) of the expected keys" do
        expect {
          expect({ :a => 1, :b => 2 }).not_to include(:d, :b)
        }.to fail_matching(%r|expected #{hash_inspect :a => 1, :b => 2} not to include :d and :b|)
      end
    end

    context "for an array target" do
      it "passes if the target does not include any of the expected" do
        expect([1, 2, 3]).not_to include(4, 5, 6)
      end

      it "fails if the target includes all of the expected" do
        expect {
          expect([1, 2, 3]).not_to include(3, 1)
        }.to fail_with(%q{expected [1, 2, 3] not to include 3 and 1})
      end

      it "fails if the target includes some (but not all) of the expected" do
        expect {
          expect([1, 2, 3]).not_to include(4, 1)
        }.to fail_with(%q{expected [1, 2, 3] not to include 4 and 1})
      end
    end
  end

  describe "expect(...).to include(:key => value)" do
    context 'for a hash target' do
      it "passes if target includes the key/value pair" do
        expect({:key => 'value'}).to include(:key => 'value')
      end

      it "passes if target includes the key/value pair among others" do
        expect({:key => 'value', :other => 'different'}).to include(:key => 'value')
      end

      it "fails if target has a different value for key" do
        expect {
          expect({:key => 'different'}).to include(:key => 'value')
        }.to fail_matching(%Q|expected {:key => "different"} to include {:key => "value"}|)
      end

      it "fails if target has a different key" do
        expect {
          expect({:other => 'value'}).to include(:key => 'value')
        }.to fail_matching(%Q|expected {:other => "value"} to include {:key => "value"}|)
      end
    end

    context 'for a non-hash target' do
      it "fails if the target does not contain the given hash" do
        expect {
          expect(['a', 'b']).to include(:key => 'value')
        }.to fail_matching(%q|expected ["a", "b"] to include {:key => "value"}|)
      end

      it "passes if the target contains the given hash" do
        expect(['a', { :key => 'value' } ]).to include(:key => 'value')
      end
    end
  end

  describe "expect(...).not_to include(:key => value)" do
    context 'for a hash target' do
      it "fails if target includes the key/value pair" do
        expect {
          expect({:key => 'value'}).not_to include(:key => 'value')
        }.to fail_matching(%Q|expected {:key => "value"} not to include {:key => "value"}|)
      end

      it "fails if target includes the key/value pair among others" do
        expect {
          expect({:key => 'value', :other => 'different'}).not_to include(:key => 'value')
        }.to fail_matching(%r|expected #{hash_inspect :key => "value", :other => "different"} not to include \{:key => "value"\}|)
      end

      it "passes if target has a different value for key" do
        expect({:key => 'different'}).not_to include(:key => 'value')
      end

      it "passes if target has a different key" do
        expect({:other => 'value'}).not_to include(:key => 'value')
      end
    end

    context "for a non-hash target" do
      it "passes if the target does not contain the given hash" do
        expect(['a', 'b']).not_to include(:key => 'value')
      end

      it "fails if the target contains the given hash" do
        expect {
          expect(['a', { :key => 'value' } ]).not_to include(:key => 'value')
        }.to fail_matching(%Q|expected ["a", {:key => "value"}] not to include {:key => "value"}|)
      end
    end
  end

  describe "expect(...).to include(:key1 => value1, :key2 => value2)" do
    context 'for a hash target' do
      it "passes if target includes the key/value pairs" do
        expect({:a => 1, :b => 2}).to include(:b => 2, :a => 1)
      end

      it "passes if target includes the key/value pairs among others" do
        expect({:a => 1, :c => 3, :b => 2}).to include(:b => 2, :a => 1)
      end

      it "fails if target has a different value for one of the keys" do
        expect {
          expect({:a => 1, :b => 2}).to include(:a => 2, :b => 2)
        }.to fail_matching(%r|expected #{hash_inspect :a => 1, :b => 2} to include #{hash_inspect :a => 2, :b => 2}|)
      end

      it "fails if target has a different value for both of the keys" do
        expect {
          expect({:a => 1, :b => 1}).to include(:a => 2, :b => 2)
        }.to fail_matching(%r|expected #{hash_inspect :a => 1, :b => 1} to include #{hash_inspect :a => 2, :b => 2}|)
      end

      it "fails if target lacks one of the keys" do
        expect {
          expect({:a => 1, :b => 1}).to include(:a => 1, :c => 1)
        }.to fail_matching(%r|expected #{hash_inspect :a => 1, :b => 1} to include #{hash_inspect :a => 1, :c => 1}|)
      end

      it "fails if target lacks both of the keys" do
        expect {
          expect({:a => 1, :b => 1}).to include(:c => 1, :d => 1)
        }.to fail_matching(%r|expected #{hash_inspect :a => 1, :b => 1} to include #{hash_inspect :c => 1, :d => 1}|)
      end
    end

    context 'for a non-hash target' do
      it "fails if the target does not contain the given hash" do
        expect {
          expect(['a', 'b']).to include(:a => 1, :b => 1)
        }.to fail_matching(%r|expected \["a", "b"\] to include #{hash_inspect :a => 1, :b => 1}|)
      end

      it "passes if the target contains the given hash" do
        expect(['a', { :a => 1, :b => 2 } ]).to include(:a => 1, :b => 2)
      end
    end
  end

  describe "expect(...).not_to include(:key1 => value1, :key2 => value2)" do
    context 'for a hash target' do
      it "fails if target includes the key/value pairs" do
        expect {
          expect({:a => 1, :b => 2}).not_to include(:a => 1, :b => 2)
        }.to fail_matching(%r|expected #{hash_inspect :a => 1, :b => 2} not to include #{hash_inspect :a => 1, :b => 2}|)
      end

      it "fails if target includes the key/value pairs among others" do
        hash = {:a => 1, :b => 2, :c => 3}
        expect {
          expect(hash).not_to include(:a => 1, :b => 2)
        }.to fail_matching(%r|expected #{hash_inspect :a => 1, :b => 2, :c => 3} not to include #{hash_inspect :a => 1, :b => 2}|)
      end

      it "fails if target has a different value for one of the keys" do
        expect {
          expect({:a => 1, :b => 2}).not_to include(:a => 2, :b => 2)
        }.to fail_matching(%r|expected #{hash_inspect :a => 1, :b => 2} not to include #{hash_inspect :a => 2, :b => 2}|)
      end

      it "passes if target has a different value for both of the keys" do
        expect({:a => 1, :b => 1}).not_to include(:a => 2, :b => 2)
      end

      it "fails if target lacks one of the keys" do
        expect {
          expect({:a => 1, :b => 1}).not_to include(:a => 1, :c => 1)
        }.to fail_matching(%r|expected #{hash_inspect :a => 1, :b => 1} not to include #{hash_inspect :a => 1, :c => 1}|)
      end

      it "passes if target lacks both of the keys" do
        expect({:a => 1, :b => 1}).not_to include(:c => 1, :d => 1)
      end
    end

    context 'for a non-hash target' do
      it "passes if the target does not contain the given hash" do
        expect(['a', 'b']).not_to include(:a => 1, :b => 1)
      end

      it "fails if the target contains the given hash" do
        expect {
          expect(['a', { :a => 1, :b => 2 } ]).not_to include(:a => 1, :b => 2)
        }.to fail_matching(%r|expected \["a", #{hash_inspect :a => 1, :b => 2}\] not to include #{hash_inspect :a => 1, :b => 2}|)
      end
    end
  end

  describe "Composing matchers with `include`" do
    RSpec::Matchers.define :a_string_containing do |expected|
      match do |actual|
        actual.include?(expected)
      end

      description do
        "a string containing '#{expected}'"
      end
    end

    describe "expect(array).to include(matcher)" do
      it "passes when the matcher matches one of the values" do
        expect([10, 20, 30]).to include( a_value_within(5).of(24) )
      end

      it 'provides a description' do
        description = include( a_value_within(5).of(24) ).description
        expect(description).to eq("include (a value within 5 of 24)")
      end

      it 'fails with a clear message when the matcher matches none of the values' do
        expect {
          expect([10, 30]).to include( a_value_within(5).of(24) )
        }.to fail_with("expected [10, 30] to include (a value within 5 of 24)")
      end

      it 'works with comparison matchers' do
        expect {
          expect([100, 200]).to include(a_value < 90)
        }.to fail_with("expected [100, 200] to include (a value < 90)")

        expect([100, 200]).to include(a_value > 150)
      end

      it 'does not treat an object that only implements #matches? as a matcher' do
        domain = Struct.new(:domain) do
          def matches?(url)
            URI(url).host == self.domain
          end
        end

        expect([domain.new("rspec.info")]).to include(domain.new("rspec.info"))

        expect {
          expect([domain.new("rspec.info")]).to include(domain.new("foo.com"))
        }.to fail_matching("expected [#{domain.new("rspec.info").inspect}] to include")
      end
    end

    describe "expect(array).to include(multiple, matcher, arguments)" do
      it "passes if target includes items satisfying all matchers" do
        expect(['foo', 'bar', 'baz']).to include(a_string_containing("ar"), a_string_containing('oo'))
      end

      it "fails if target does not include an item satisfying any one of the items" do
        expect {
          expect(['foo', 'bar', 'baz']).to include(a_string_containing("ar"), a_string_containing("abc"))
        }.to fail_matching(%Q|expected #{['foo', 'bar', 'baz'].inspect} to include (a string containing 'ar') and (a string containing 'abc')|)
      end
    end

    describe "expect(hash).to include(key => matcher)" do
      it "passes when the matcher matches" do
        expect(:a => 12).to include(:a => a_value_within(3).of(10))
      end

      it 'provides a description' do
        description = include(:a => a_value_within(3).of(10)).description
        expect(description).to eq("include {:a => (a value within 3 of 10)}")
      end

      it "fails with a clear message when the matcher does not match" do
        expect {
          expect(:a => 15).to include(:a => a_value_within(3).of(10))
        }.to fail_matching("expected {:a => 15} to include {:a => (a value within 3 of 10)}")
      end
    end

    describe "expect(hash).to include(key_matcher)" do
      it "passes when the matcher matches a key", :if => (RUBY_VERSION.to_f > 1.8) do
        expect(:drink => "water", :food => "bread").to include(a_string_matching(/foo/))
      end

      it 'provides a description' do
        description = include(a_string_matching(/foo/)).description
        expect(description).to eq("include (a string matching /foo/)")
      end

      it 'fails with a clear message when the matcher does not match', :if => (RUBY_VERSION.to_f > 1.8) do
        expect {
          expect(:drink => "water", :food => "bread").to include(a_string_matching(/bar/))
        }.to fail_matching('expected {:drink => "water", :food => "bread"} to include (a string matching /bar/)')
      end
    end

    describe "expect(array).not_to include(multiple, matcher, arguments)" do
      it "passes if none of the target values satisfies any of the matchers" do
        expect(['foo', 'bar', 'baz']).not_to include(a_string_containing("gh"), a_string_containing('de'))
      end

      it 'fails if all of the matchers are satisfied by one of the target values' do
        expect {
          expect(['foo', 'bar', 'baz']).not_to include(a_string_containing("ar"), a_string_containing('az'))
        }.to fail_matching(%Q|expected #{['foo', 'bar', 'baz'].inspect} not to include (a string containing 'ar') and (a string containing 'az')|)
      end

      it 'fails if the some (but not all) of the matchers are satisifed' do
        expect {
          expect(['foo', 'bar', 'baz']).not_to include(a_string_containing("ar"), a_string_containing('bz'))
        }.to fail_matching(%Q|expected #{['foo', 'bar', 'baz'].inspect} not to include (a string containing 'ar') and (a string containing 'bz')|)
      end
    end
  end

  include RSpec::Matchers::Pretty
  # We have to use Hash#inspect in examples that have multi-entry
  # hashes because the #inspect output on 1.8.7 is non-deterministic
  # due to the fact that hashes are not ordered. So we can't simply
  # put a literal string for what we expect because it varies.
  if RUBY_VERSION.to_f == 1.8
    def hash_inspect(hash)
      /\{(#{hash.map { |key,value| "#{key.inspect} => #{value.inspect}.*" }.join "|" }){#{hash.size}}\}/
    end
  else
    def hash_inspect(hash)
      improve_hash_formatting hash.inspect
    end
  end
end

