require "../spec_helper"

Spectator.describe ActivityPub do
  before_each { Balloon.database.exec "BEGIN TRANSACTION" }
  after_each { Balloon.database.exec "ROLLBACK" }

  describe ".from_json_ld" do
    it "instantiates the correct subclass" do
      expect(described_class.from_json_ld(%q[{"@type":"Person"}])).to be_a(ActivityPub::Actor::Person)
      expect(described_class.from_json_ld(%q[{"@type":"Collection"}])).to be_a(ActivityPub::Collection)
    end

    subject { ActivityPub::Activity.new(iri: "https://test.test/foo_bar").save }

    it "creates an instance if one doesn't exist" do
      json = %q[{"@id":"https://test.test/bar_foo","@type":"Activity"}]
      expect{described_class.from_json_ld(json).save}.to change{ActivityPub::Activity.count}.by(1)
    end

    it "updates the instance if it already exists" do
      json = %q[{"@context":"https://www.w3.org/ns/activitystreams","@id":"https://test.test/foo_bar","@type":"Activity","summary":"foo bar baz"}]
      expect{described_class.from_json_ld(json).save}.to change{ActivityPub::Activity.find(subject.iri).summary}
    end
  end
end
