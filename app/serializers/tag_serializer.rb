class TagSerializer
  def self.call(tag)
    {
      id: tag.id,
      name: tag.name,
      system: tag.system
    }
  end
end
