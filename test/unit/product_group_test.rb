require 'test_helper'

class ProductGroupTest < Test::Unit::TestCase
  context "ProductGroup" do
    setup do
      [Taxonomy, Variant, Product, Variant].each(&:delete_all)
      @numbers = %w{one two three four five six}
      @taxonomy = Taxonomy.find_or_create_by_name("test_taxonomy")
      @taxons = (0..1).map{|x|
        Taxon.find_by_name("test_taxon_#{x}") ||
          Taxon.create(:name => "test_taxon_#{x}", :taxonomy_id => @taxonomy.id)
      }
      @products = (0..4).map do |x|
        unless pr = Product.find_by_name("test product #{@numbers[x]}")
          pr = Factory(:product,
            :price => (x+1)*10,
            :name => "test product #{@numbers[x]}"
          )
          pr.taxons << @taxons[x%2]
          pr.save
        end
        pr
      end
    end

    context "scope merging" do
      setup do
        @pg = ProductGroup.new
      end

      should "use last order passed" do
        @pg.add_scope("descend_by_name")
        @pg.add_scope("ascend_by_created_at")
        assert_equal("ascend_by_created_at", @pg.order)
      end
    end

    ###################### NORMAL URL ########################################
    context "from normal url" do
      setup do
        @pg = ProductGroup.from_url('/s/name_like_any/one,two,five/master_price_lt/30/descend_by_name')
      end

      should "not be saved and have sane defaults" do
        assert(@pg.kind_of?(ProductGroup),
          "ProductGroup is a #{@pg.class.name} instead of Project Group")
        assert(@pg.new_record?,
          "ProductGroup is not new record")
        assert(@pg.name.blank?,
          "ProductGroup.name is not blank but #{@pg.name}")
        assert(@pg.permalink.blank?,
          "ProductGroup.name is not blank but #{@pg.permalink}")
      end

      should "generate correct scopes" do
        assert @pg.product_scopes
        
        assert_equal([
            {
              "product_group_id"=>nil,
              "name"=>"name_like_any",
              "arguments"=>["one", "two", "five"]
            },{
              "product_group_id"=>nil,
              "name"=>"master_price_lt",
              "arguments"=>["30"]
            }
          ], @pg.product_scopes.map(&:attributes))
      end

      should "find products" do
        products = %w{one two five}.map{|name|
          Product.find(:all, :conditions => ["name LIKE ?", "%#{name}%"])
        }.flatten.reject{|pr| pr.master.price >= 30}.sort_by{|pr| pr.name}.reverse
        assert_equal(products.map(&:name), @pg.products.map(&:name))

      end

      should "have correct order" do
        assert_equal(@pg.order, "descend_by_name")
        assert_equal("products.name DESC", @pg.products.scope(:find)[:order])
      end
    end

    ###################### NORMAL URL WITH TAXON################################
    context "from normal url with taxon" do
      setup do
        @pg = ProductGroup.from_url('/t/test_taxon_0/s/name_like_any/one,two,five/master_price_lt/30')
      end

      should "not be saved and have sane defaults" do
        assert(@pg.kind_of?(ProductGroup),
          "ProductGroup is a #{@pg.class.name} instead of Project Group")
        assert(@pg.new_record?,
          "ProductGroup is not new record")
        assert(@pg.name.blank?,
          "ProductGroup.name is not blank but #{@pg.name}")
        assert(@pg.permalink.blank?,
          "ProductGroup.name is not blank but #{@pg.permalink}")
      end

      should "generate correct scopes" do
        assert @pg.product_scopes

        assert_equal([
            {
              "product_group_id"=>nil,
              "name"=>"name_like_any",
              "arguments"=>["one", "two", "five"]
            },{
              "product_group_id"=>nil,
              "name"=>"master_price_lt",
              "arguments"=>["30"]
            },{
              "product_group_id"=>nil,
              "name"=>"in_taxon",
              "arguments" => ["test_taxon_0"]
            }
          ], @pg.product_scopes.map(&:attributes))
      end

      should "find products" do
        products = %w{one five}.map{|name|
          Product.find(:all, :conditions => ["name LIKE ?", "%#{name}%"])
        }.flatten.reject{|pr| pr.master.price >= 30}
        assert_equal(products.map(&:name), @pg.products.map(&:name))

      end

      should "have correct order" do
        assert_equal(@pg.order, nil)
        assert_equal('taxons.lft', @pg.products.scope(:find)[:order].gsub(/["'`]/, ''))
      end
    end

    ###################### copy of another product group #########################
    context "from another product group" do
      setup do
        ProductGroup.create!({
            :name => "test_pg",
            :order => "descend_by_created_at",
            :product_scopes_attributes => [
              {
                "name"=>"name_like_any",
                "arguments"=>["three", "four", "five"]
              }
            ]
          })
        @pg = ProductGroup.from_url('/pg/test_pg')
      end

      should "not be saved and have sane defaults" do
        assert(@pg.kind_of?(ProductGroup),
          "ProductGroup is a #{@pg.class.name} instead of Project Group")
        assert(@pg.new_record?,
          "ProductGroup is not new record")
        assert(@pg.name.blank?,
          "ProductGroup.name is not blank but #{@pg.name}")
        assert(@pg.permalink.blank?,
          "ProductGroup.name is not blank but #{@pg.permalink}")
      end

      should "generate correct scopes" do
        assert @pg.product_scopes

        assert_equal([
            {
              "product_group_id"=>nil,
              "name"=>"name_like_any",
              "arguments"=>["three", "four", "five"]
            }
          ], @pg.product_scopes.map(&:attributes))
      end

      should "find products" do
        products = %w{three four five}.map{|name|
          Product.find(:all, :conditions => ["name LIKE ?", "%#{name}%"])
        }.flatten.sort_by{|pr| pr.name}
        assert_equal(products.map(&:name), @pg.products.map(&:name).sort)
      end

      should "have correct order" do
        assert_equal(@pg.order, "descend_by_created_at")
        assert_equal("products.created_at DESC", @pg.products.scope(:find)[:order])
      end
    end

    ###################### copy of another product group with taxon #############
    context "from another product group with taxon" do
      setup do
        ProductGroup.create!({
            :name => "test_pg",
            :order => "descend_by_created_at",
            :product_scopes_attributes => [
              {
                "name"=>"name_like_any",
                "arguments"=>["three", "four", "five"]
              }
            ]
          })
        @pg =  ProductGroup.from_url('/t/test_taxon_1/pg/test_pg')
      end

      should "not be saved and have sane defaults" do
        assert(@pg.kind_of?(ProductGroup),
          "ProductGroup is a #{@pg.class.name} instead of Project Group")
        assert(@pg.new_record?,
          "ProductGroup is not new record")
        assert(@pg.name.blank?,
          "ProductGroup.name is not blank but #{@pg.name}")
        assert(@pg.permalink.blank?,
          "ProductGroup.name is not blank but #{@pg.permalink}")
      end

      should "generate correct scopes" do
        assert @pg.product_scopes

        assert_equal([
            {
              "product_group_id"=>nil,
              "name"=>"name_like_any",
              "arguments"=>["three", "four", "five"]
            },{
              "product_group_id"=>nil,
              "name"=>"in_taxon",
              "arguments" => ["test_taxon_1"]
            }
          ], @pg.product_scopes.map(&:attributes))
      end

      should "find products" do
        products = %w{four}.map{|name|
          Product.find(:all, :conditions => ["name LIKE ?", "%#{name}%"])
        }.flatten.sort_by{|pr| pr.created_at}.reverse
        assert_equal(products.map(&:name), @pg.products.map(&:name))
      end

      should "have correct order" do
        assert_equal(@pg.order, "descend_by_created_at")
        assert_equal("products.created_at DESC", @pg.products.scope(:find)[:order])
      end
    end

    teardown do
      Taxonomy.delete_all "name like 'test_%'"
      Taxon.delete_all "name like 'test_%'"
      @products && @products.each(&:destroy)
    end
  end
end
