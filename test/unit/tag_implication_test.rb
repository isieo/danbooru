require File.dirname(__FILE__) + '/../test_helper'

class TagImplicationTest < ActiveSupport::TestCase
  context "A tag implication" do
    setup do
      MEMCACHE.flush_all
      @user = Factory.create(:user)
    end
    
    should "not validate when a circular relation is created" do
      ti1 = Factory.create(:tag_implication, :antecedent_name => "aaa", :consequent_name => "bbb")
      ti2 = Factory.build(:tag_implication, :antecedent_name => "bbb", :consequent_name => "aaa")
      ti2.save
      assert(ti2.errors.any?, "Tag implication should not have validated.")
      assert_equal("Tag implication can not create a circular relation with another tag implication", ti2.errors.full_messages.join(""))
    end
    
    should "not allow for duplicates" do
      ti1 = Factory.create(:tag_implication, :antecedent_name => "aaa", :consequent_name => "bbb")
      ti2 = Factory.build(:tag_implication, :antecedent_name => "aaa", :consequent_name => "bbb")
      ti2.save
      assert(ti2.errors.any?, "Tag implication should not have validated.")
      assert_equal("Antecedent name has already been taken", ti2.errors.full_messages.join(""))
    end
  
    should "clear the cache upon saving" do
      ti1 = Factory.create(:tag_implication, :antecedent_name => "aaa", :consequent_name => "bbb")
      assert_equal(["bbb"], ti1.descendant_names_array)
      assert_equal(["bbb"], MEMCACHE.get("ti:aaa"))
      ti1.update_attributes(
        :consequent_name => "ccc",
        :updater_id => @user.id,
        :updater_ip_addr => "127.0.0.1"
      )
      assert_nil(MEMCACHE.get("ti:aaa"))
    end
    
    should "clear the cache upon destruction" do
      ti1 = Factory.create(:tag_implication, :antecedent_name => "aaa", :consequent_name => "bbb")
      ti1.destroy
      assert_nil(MEMCACHE.get("ti:aaa"))
    end
    
    should "calculate all its descendants" do
      ti1 = Factory.create(:tag_implication, :antecedent_name => "bbb", :consequent_name => "ccc")
      assert_equal("ccc", ti1.descendant_names)
      assert_equal(["ccc"], ti1.descendant_names_array)      
      ti2 = Factory.create(:tag_implication, :antecedent_name => "aaa", :consequent_name => "bbb")
      assert_equal("bbb ccc", ti2.descendant_names)
      assert_equal(["bbb", "ccc"], ti2.descendant_names_array)
      ti1.reload
      assert_equal("ccc", ti1.descendant_names)
      assert_equal(["ccc"], ti1.descendant_names_array)
    end
    
    should "cache its descendants" do
      ti1 = Factory.create(:tag_implication, :antecedent_name => "aaa", :consequent_name => "bbb")
      assert_equal(["bbb"], ti1.descendant_names_array)
      assert_equal(["bbb"], MEMCACHE.get("ti:aaa"))
    end
    
    should "update its descendants on save" do
      ti1 = Factory.create(:tag_implication, :antecedent_name => "aaa", :consequent_name => "bbb")
      ti2 = Factory.create(:tag_implication, :antecedent_name => "ccc", :consequent_name => "ddd")
      ti2.update_attributes(
        :antecedent_name => "bbb",
        :updater_id => @user.id,
        :updater_ip_addr => "127.0.0.1"
      )
      ti1.reload
      ti2.reload
      assert_equal("bbb ddd", ti1.descendant_names)
      assert_equal("ddd", ti2.descendant_names)
    end
    
    should "update the decendants for its parent on save" do
      ti1 = Factory.create(:tag_implication, :antecedent_name => "aaa", :consequent_name => "bbb")
      ti2 = Factory.create(:tag_implication, :antecedent_name => "bbb", :consequent_name => "ccc")
      ti3 = Factory.create(:tag_implication, :antecedent_name => "ccc", :consequent_name => "ddd")
      ti4 = Factory.create(:tag_implication, :antecedent_name => "ccc", :consequent_name => "eee")
      ti1.reload
      ti2.reload
      ti3.reload
      ti4.reload
      assert_equal("bbb ccc eee ddd", ti1.descendant_names)
      assert_equal("ccc eee ddd", ti2.descendant_names)
      assert_equal("ddd", ti3.descendant_names)
      assert_equal("eee", ti4.descendant_names)
    end
    
    should "update any affected post upon save" do
      p1 = Factory.create(:post, :tag_string => "aaa bbb ccc")
      ti1 = Factory.create(:tag_implication, :antecedent_name => "aaa", :consequent_name => "xxx")
      ti2 = Factory.create(:tag_implication, :antecedent_name => "aaa", :consequent_name => "yyy")
      p1.reload
      assert_equal("aaa yyy xxx bbb ccc", p1.tag_string)
    end
  end
end