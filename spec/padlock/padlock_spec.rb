require "spec_helper"

describe Padlock do
  describe ".config" do
    let(:config) { nil }

    before { Padlock.class_variable_set(:@@config, config) }

    it { expect( Padlock.config ).to be_a_kind_of OpenStruct }

    it "returns a persistant object" do
      expect( Padlock.config.random ).to be_nil
      Padlock.config.random = "value"
      expect( Padlock.config.random ).to eq "value"
    end
  end

  describe ".lock" do
    let(:object) { double(:object) }
    let(:user) { double(:user) }
    let(:padlocks) { double(:padlocks) }

    before { user.stub(:padlocks).and_return(padlocks) }

    it "unlocks the object before attempting to lock it" do
      object.should_receive(:unlock!)
      padlocks.stub(:create)
      object.stub(:reload)
      Padlock.lock(user, object)
    end

    it "creates the Padlock::Instance" do
      object.stub(:unlock!)
      padlocks.should_receive(:create).with(lockable: object)
      object.stub(:reload)
      Padlock.lock(user, object)
    end

    it "reloads the object" do
      object.stub(:unlock!)
      padlocks.stub(:create)
      object.should_receive(:reload)
      Padlock.lock(user, object)
    end

    it "accepts a splat of objects" do
      expect(object).to receive(:unlock!).exactly(2).times
      expect(padlocks).to receive(:create).exactly(2).times
      expect(object).to receive(:reload).exactly(2).times
      Padlock.lock(user, object, object)
    end
  end

  describe ".locked?" do
    let(:object) { User.create!(name: "Annie Bob") }

    it do
      object.should_receive(:locked?).and_return(true)
      expect(Padlock.locked?(object)).to eq true
    end
  end

  describe ".unlock!" do
    let(:object)  { double(:object) }

    context "single object" do
      it do
        object.should_receive(:unlock!).exactly(1).times
        Padlock.unlock!(object)
      end
    end

    context "multiple objects" do
      it do
        object.should_receive(:unlock!).exactly(2).times
        Padlock.unlock!(object, object)
      end
    end
  end

  describe ".unlocked?" do
    let(:object) { User.create!(name: "Annie Bob") }

    it do
      object.should_receive(:unlocked?).and_return(true)
      expect(Padlock.unlocked?(object)).to eq true
    end
  end

  describe ".unlock_stale" do
    let(:object) { LockableObject.create!(created_at: Time.zone.now - 1.week, updated_at: updated_at) }
    let(:locked?) { true }
    let(:updated_at) { Time.zone.now - 2.hours }
    let(:fake_relation) { double(:fake_relation) }

    before do
      Padlock::Instance.should_receive(:where).and_return(fake_relation)
      fake_relation.should_receive(:destroy_all)
      Padlock.unlock_stale
    end

    it "unlocks all lockables that have been locked more than 1 hour" do
      expect(object).to be_unlocked
    end
  end

  describe ".touch" do
    let(:object) { LockableObject.create }
    let(:object2) { LockableObject.create }
    let(:locked?) { true }
    let(:fake_padlocks) { double("fake_padlocks") }
    let(:fake_padlock_ids) { [object.id, object2.id] }

    before do
      object.stub(:locked?).and_return(locked?)
      # object.stub(:padlock).and_return(fake_padlock)
    end

    context "when locked" do
      let(:locked?) { true }

      it "sets a new value on the updated_at column and saves it" do
        expect(object).to receive(:locked?).and_return(true)
        expect(object2).to receive(:locked?).and_return(true)
        expect(object).to receive(:id)
        expect(object2).to receive(:id)

        proxy = double(:fake_padlocks)
        expect(proxy).to receive_message_chain("update_all")
          .with(hash_including(:updated_at => anything))
          .and_return(true)

        expect(Padlock::Instance).to receive_message_chain("where")
          .with(hash_including(:lockable_id))
          .and_return(proxy)

        res = Padlock.touch(object, object2)
        expect(res).to be_truthy
      end
    end

    context "when unlocked" do
      let(:locked?) { false }

      it "leaves the object unaffected" do
        expect(object).to_not receive(:id)
        expect(Padlock).to_not receive(:where)
        res = Padlock.touch(object)
        expect(res).to be_falsy
      end
    end
  end
end
