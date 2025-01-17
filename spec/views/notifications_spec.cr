require "../../src/models/relationship/content/follow/hashtag"
require "../../src/models/relationship/content/follow/mention"

require "../spec_helper/factory"
require "../spec_helper/controller"

Spectator.describe "notifications partial" do
  setup_spec

  include Ktistec::Controller
  include Ktistec::ViewHelper::ClassMethods

  describe "notifications.html.slang" do
    let(env) { env_factory("GET", "/notifications") }

    subject do
      begin
        XML.parse_html(render "./src/views/actors/notifications.html.slang")
      rescue XML::Error
        XML.parse_html("<div/>").document
      end
    end

    let(account) { register }
    let(actor) { account.actor }

    let(notifications) { actor.notifications }

    it "renders an empty page" do
      expect(subject.xpath_nodes("//text()")).to have(/There is nothing here/)
    end

    context "given an announce notification" do
      let_build(:announce)
      let_create!(:notification_announce, owner: actor, activity: announce)

      it "renders a sharing message" do
        expect(subject.xpath_nodes("//article[contains(@class,'event')]//text()").join).
          to eq("#{announce.actor.display_name} shared your post.")
      end

      context "given another announce notification" do
        let_create!(:announce, named: another, object: announce.object)

        it "renders a sharing message" do
          expect(subject.xpath_nodes("//article[contains(@class,'event')]//text()").join).
            to eq("#{announce.actor.display_name} and 1 other shared your post.")
        end
      end
    end

    context "given a like notification" do
      let_build(:like)
      let_create!(:notification_like, owner: actor, activity: like)

      it "renders a liking message" do
        expect(subject.xpath_nodes("//article[contains(@class,'event')]//text()").join).
          to eq("#{like.actor.display_name} liked your post.")
      end

      context "given another like notification" do
        let_create!(:like, named: another, object: like.object)

        it "renders a liking message" do
          expect(subject.xpath_nodes("//article[contains(@class,'event')]//text()").join).
            to eq("#{like.actor.display_name} and 1 other liked your post.")
        end
      end
    end

    context "given a hashtag notification" do
      let_build(:object, published: Time.utc)
      let_create!(:notification_hashtag, owner: actor, object: object)

      let_create!(:follow_hashtag_relationship, named: nil, actor: actor, name: "foo")

      before_each do
        Factory.create(:hashtag, name: "foo", subject: object)
        Factory.create(:hashtag, name: "bar", subject: object)
      end

      it "renders a tagged message" do
        expect(subject.xpath_nodes("//article[contains(@class,'event')]//text()").join).
          to eq("#{object.attributed_to.display_name} tagged a post with #foo.")
      end

      context "and multiple objects with nearly the same created_at time" do
        let_create!(:object, named: object1, published: Time.utc)
        let_create!(:object, named: object2, published: Time.utc)

        before_each do
          Factory.create(:hashtag, name: "bar", subject: object1)
          Factory.create(:hashtag, name: "bar", subject: object2)
        end

        it "renders a tagged message" do
          expect(subject.xpath_nodes("//article[contains(@class,'event')]//text()").join).
            to eq("#{object.attributed_to.display_name} tagged a post with #foo.")
        end

        context "with the same hashtag" do
          before_each do
            Factory.create(:hashtag, name: "foo", subject: object1)
            Factory.create(:hashtag, name: "foo", subject: object2)
          end

          it "renders a different message" do
            expect(subject.xpath_nodes("//article[contains(@class,'event')]//text()").join).
              to eq("There are new posts tagged with #foo.")
          end
        end
      end
    end

    context "given a mention notification" do
      let_build(:object)
      let_create!(:notification_mention, owner: actor, object: object)

      let_create!(:follow_mention_relationship, named: nil, actor: actor, name: "foo")

      before_each do
        Factory.create(:mention, name: "foo", subject: object)
        Factory.create(:mention, name: "bar", subject: object)
      end

      it "renders a tagged message" do
        expect(subject.xpath_nodes("//article[contains(@class,'event')]//text()").join).
          to eq("#{object.attributed_to.display_name} tagged a post with @foo.")
      end
    end

    context "given a thread notification for a reply" do
      let_build(:object)
      let_build(:object, named: reply, in_reply_to: object)
      let_create!(:notification_thread, owner: actor, object: reply)

      pre_condition { expect(reply.root?).to be_false }

      it "renders a replied to message" do
        expect(subject.xpath_nodes("//article[contains(@class,'event')]//text()").join).
          to eq("#{reply.attributed_to.display_name} replied to a thread you follow.")
      end
    end

    context "given a thread notification for the root" do
      let_build(:object)
      let_create!(:notification_thread, owner: actor, object: object)

      pre_condition { expect(object.root?).to be_true }

      it "renders a fetch the root of the thread message" do
        expect(subject.xpath_nodes("//article[contains(@class,'event')]//text()").join).
          to eq("There are replies to a thread you follow.")
      end
    end
  end

  describe "notifications.json.ecr" do
    let(env) { env_factory("GET", "/notifications") }

    subject do
      begin
        JSON.parse(render "./src/views/actors/notifications.json.ecr")
      rescue JSON::ParseException
        JSON.parse("{}")
      end
    end

    let(account) { register }
    let(actor) { account.actor }

    let(notifications) { actor.notifications }

    it "renders an empty collection" do
      expect(subject["first"]["orderedItems"].as_a).to be_empty
    end
  end
end
