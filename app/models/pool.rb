class Pool < ActiveRecord::Base
  attr_accessor :updater_id, :updater_ip_addr
  validates_uniqueness_of :name
  validates_presence_of :name, :updater_id, :updater_ip_addr
  validates_format_of :name, :with => /\A[^\s;,]+\Z/, :on => :create, :message => "cannot have whitespace, commas, or semicolons"
  belongs_to :creator, :class_name => "User"
  belongs_to :updater, :class_name => "User"
  has_many :versions, :class_name => "PoolVersion"
  after_save :create_version
  
  def self.create_anonymous(creator, creator_ip_addr)
    pool = Pool.create(:name => "TEMP:#{Time.now.to_f}.#{rand(1_000_000)}", :creator => creator, :updater_id => creator.id, :updater_ip_addr => creator_ip_addr)
    pool.update_attribute(:name, "anonymous:#{pool.id}")
    pool
  end
  
  def revert_to!(version)
    self.post_ids = version.post_ids
    save
  end
  
  def add_post!(post)
    self.post_ids += " #{post.id}"
    self.post_ids.strip!
    save
  end
  
  def remove_post!(post)
    post_ids.gsub!(/(?:\A| )#{post.id}(?:\Z| )/, " ")
    post_ids.strip!
    save
  end
  
  def posts(options = {})
    offset = options[:offset] || 0
    limit = options[:limit] || 20
    ids = post_id_array[offset, limit]
    Post.where(["id IN (?)", ids])
  end
  
  def post_id_array
    @post_id_array ||= post_ids.scan(/\d+/).map(&:to_i)
  end
  
  def clear_post_id_array
    @post_id_array = nil
  end
  
  def neighbor_posts(post)
    post_ids =~ /\A#{post.id} (\d+)|(\d+) #{post.id} (\d+)|(\d+) #{post.id}\Z/
    
    if $2 && $3
      {:previous => $2.to_i, :next => $3.to_i}
    elsif $1
      {:next => $1.to_i}
    elsif $4
      {:previous => $4.to_i}
    else
      nil
    end
  end
  
  def create_version
    last_version = versions.last
    
    if last_version && updater_ip_addr == last_version.updater_ip_addr && updater_id == last_version.updater_id
      last_version.update_attribute(:post_ids, post_ids)
    else
      versions.create(
        :post_ids => post_ids,
        :updater_id => updater_id,
        :updater_ip_addr => updater_ip_addr
      )
    end
  end
  
  def reload(options = {})
    super
    clear_post_id_array
  end
end