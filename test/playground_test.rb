require "test/test_helper"

class PlaygroundTest < MiniTest::Unit::TestCase
  def setup
    @namespace = "vanity:1"
  end

  def test_has_one_global_instance
    assert instance = Vanity.playground
    assert_equal instance, Vanity.playground
  end

  def test_playground_namespace
    assert @namespace, Vanity.playground.namespace
  end


  # -- Loading experiments --

  def test_fails_if_cannot_load_named_experiment
    assert_raises LoadError do
      experiment("Green button")
    end
  end

  def test_loading_experiment
    Vanity.playground.load_path = Dir.tmpdir
    File.open File.join(Dir.tmpdir, "green_button.rb"), "w" do |f|
      f.write <<-RUBY
        ab_test "Green Button" do
          def xmts
            "x"
          end
        end
      RUBY
    end
    assert_equal "x", experiment(:green_button).xmts
  end

  def test_fails_if_error_loading_experiment
    Vanity.playground.load_path = Dir.tmpdir
    File.open File.join(Dir.tmpdir, "green_button.rb"), "w" do |f|
      f.write "fail 'yawn!'"
    end
    assert_raises LoadError do
      experiment(:green_button)
    end
  end

  def test_complains_if_not_defined_where_expected
    Vanity.playground.load_path = Dir.tmpdir
    File.open File.join(Dir.tmpdir, "green_button.rb"), "w" do |f|
      f.write ""
    end
    assert_raises LoadError do
      experiment("Green button")
    end
  end

  def test_reloading_experiments
    Vanity.playground.define(:ab, :ab_test) {}
    Vanity.playground.define(:cd, :ab_test) {}
    assert 2, Vanity.playground.experiments.count
    Vanity.playground.reload!
    assert_empty Vanity.playground.experiments
  end

  # -- Defining experiment --
  
  def test_can_access_experiment_by_name_or_id
    exp = Vanity.playground.define(:green_button, :ab_test) { }
    assert_equal exp, experiment("Green Button")
    assert_equal exp, experiment(:green_button)
  end

  def test_fail_when_defining_same_experiment_twice
    Vanity.playground.define("Green Button", :ab_test) { }
    assert_raises RuntimeError do
      Vanity.playground.define("Green Button", :ab_test) { }
    end
  end

  def test_uses_playground_namespace_for_experiment
    Vanity.playground.define(:green_button, :ab_test) { }
    assert_equal "#{@namespace}:green_button", experiment(:green_button).send(:key)
    assert_equal "#{@namespace}:green_button:participants", experiment(:green_button).send(:key, "participants")
  end

end
