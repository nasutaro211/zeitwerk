require "test_helper"

class TestConcurrency < LoaderTest
  test "constant definition is synchronized" do
    files = [["m.rb", <<-EOS]]
      module M
        sleep 0.5

        def self.works?
          true
        end
      end
    EOS
    with_setup(files) do
      t = Thread.new { M }
      assert M.works?
      t.join
    end
  end

  test "module autovivification" do
    $test_admin_const_set_calls = 0

    files = [["admin/v2/user.rb", "class Admin::V2::User; end"]]
    with_setup(files) do
      assert Admin

      def Admin.const_set(cname, mod)
        $test_admin_const_set_calls += 1
        sleep 0.5
        super
      end
      Array.new(2) { Thread.new { Admin::V2 } }.each(&:join)

      assert_equal 1, $test_admin_const_set_calls
    end
  end
end
