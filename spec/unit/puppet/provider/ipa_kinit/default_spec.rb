require 'spec_helper'

describe Puppet::Type.type(:ipa_kinit).provider(:default) do
  let(:name) { 'admin' }
  let(:properties) do
    {
      name: name,
      ensure: :present,
      password: 'AdminPassword123',
    }
  end
  let(:resource) { Puppet::Type.type(:ipa_kinit).new(properties) }
  let(:provider) { resource.provider }

  describe '#read_instance' do
    it 'return a resource when name matches' do
      klist_return = <<-EOS
Principal name                 Cache name
--------------                 ----------
admin@IPA.DOMAIN.TLD           KCM:0
EOS
      provider.expects(:klist).with('-l').returns(klist_return)
      expect(provider.read_instance).to eq(ensure: :present,
                                           name: name,
                                           principal_name: 'admin@IPA.DOMAIN.TLD')
    end

    it 'return {ensure: absent} instance when no names match' do
      klist_return = <<-EOS
Principal name                 Cache name
--------------                 ----------
xyz@IPA.DOMAIN.TLD             KCM:0
EOS
      provider.expects(:klist).with('-l').returns(klist_return)
      expect(provider.read_instance).to eq(ensure: :absent, name: name)
    end

    it 'return good instance when realm isnt passed in, as long as user matches' do
      klist_return = <<-EOS
Principal name                 Cache name
--------------                 ----------
admin@DIFFERENT.DOMAIN.TLD     KCM:0
EOS
      provider.expects(:klist).with('-l').returns(klist_return)
      expect(provider.read_instance).to eq(ensure: :present,
                                           name: name,
                                           principal_name: 'admin@DIFFERENT.DOMAIN.TLD')
    end

    it 'return {ensure: absent} instance when klist fails' do
      provider.expects(:klist).with('-l').raises(Puppet::ExecutionFailure.new('x'))
      expect(provider.read_instance).to eq(ensure: :absent, name: name)
    end

    context 'with realm set' do
      let(:properties) do
        {
          name: name,
          realm: 'EXPECTED.DOMAIN.TLD',
        }
      end

      it 'return a resource when name and realm matches' do
        klist_return = <<-EOS
Principal name                 Cache name
--------------                 ----------
admin@EXPECTED.DOMAIN.TLD      KCM:0
EOS
        provider.expects(:klist).with('-l').returns(klist_return)
        expect(provider.read_instance).to eq(ensure: :present,
                                             name: name,
                                             principal_name: 'admin@EXPECTED.DOMAIN.TLD',
                                             realm: 'EXPECTED.DOMAIN.TLD')
      end

      it 'return a {ensure: absent} instance when name matches but realm doesnt match' do
        klist_return = <<-EOS
Principal name                 Cache name
--------------                 ----------
admin@BAD.DOMAIN.TLD      KCM:0
EOS
        provider.expects(:klist).with('-l').returns(klist_return)
        expect(provider.read_instance).to eq(ensure: :absent, name: name)
      end
    end
  end

  describe '#flush_instance' do
    context 'when destroying' do
      let(:properties) do
        {
          name: name,
          ensure: :absent,
        }
      end

      let(:provider) do
        prov = resource.provider
        props = { principal_name: 'admin@IPA.DOMAIN.TLD' }
        prov.instance_variable_set(:@cached_instance, properties.merge(props))
        prov
      end

      it 'run kdestroy with the principal name' do
        provider.expects(:kdestroy).with(['-p', 'admin@IPA.DOMAIN.TLD'])
        provider.flush_instance
      end
    end

    context 'when creating' do
      before(:each) do
        provider.expects(:command).with(:kinit).returns('/bin/kinit')
      end

      it 'run kinit with username and password' do
        command_str = 'echo $KINIT_PASSWORD | /bin/kinit admin'
        Puppet::Util::Execution.expects(:execute).with(
          command_str,
          override_locale: false,
          failonfail: true,
          combine: true,
          custom_environment: {
            'KINIT_PASSWORD' => 'AdminPassword123',
          },
        )
        provider.flush_instance
      end

      context 'with realm' do
        let(:properties) do
          {
            name: name,
            ensure: :present,
            password: 'AdminPassword123',
            realm: 'EXPECTED.DOMAIN.TLD',
          }
        end

        it 'run kinit with username@realm specified' do
          command_str = 'echo $KINIT_PASSWORD | /bin/kinit admin@EXPECTED.DOMAIN.TLD'
          Puppet::Util::Execution.expects(:execute).with(
            command_str,
            override_locale: false,
            failonfail: true,
            combine: true,
            custom_environment: {
              'KINIT_PASSWORD' => 'AdminPassword123',
            },
          )
          provider.flush_instance
        end
      end
    end
  end
end
