#!/usr/bin/env rspec

require_relative "../../test_helper"
require "y2packager/clients/inst_productsources"

describe Yast::InstProductsourcesClient do
  subject(:client) { described_class.new }

  describe "#main" do
    before do
      allow(Yast::Sequencer).to receive(:Run)
      allow(Yast::Wizard).to receive(:OpenDialog)
      allow(Yast::Wizard).to receive(:CloseDialog)
    end

    it "returns :auto if AddOnProduct is set to skip" do
      allow(Yast::AddOnProduct).to receive(:skip_add_ons).and_return(true)

      expect(client.main).to eq :auto
    end

    context "run as command line" do
      before do
        allow(Yast::Mode).to receive(:normal).and_return(true)
        allow(Yast::WFM).to receive(:Args).and_return(["help"])
        allow(Yast::CommandLine).to receive(:Run)
      end

      it "runs command line" do
        expect(Yast::CommandLine).to receive(:Run)

        client.main
      end

      it "returns auto" do
        expect(client.main).to eq :auto
      end
    end

    it "opens wizard in normal mode" do
      expect(Yast::Wizard).to receive(:OpenDialog)
      expect(Yast::Wizard).to receive(:CloseDialog)

      allow(Yast::Mode).to receive(:normal).and_return(true)

      client.main
    end
  end

  describe "#ParseListOfSources" do
    let(:file) do
      File.expand_path("../../../data/_openSUSE_Leap_15.0_Default.xml", __FILE__)
    end
    let(:url) { "http://yast.rulezz.com" }

    def list_of_repos
      client.instance_variable_get(:@list_of_repos)
    end

    before do
      client.instance_variable_set(:@list_of_repos, {})
    end

    it "returns false if file does not exist" do
      expect(client.ParseListOfSources("/dev/non_existing_device", url)).to eq false
    end

    it "returns false if file is empty" do
      expect(client.ParseListOfSources("/dev/zero", url)).to eq false
    end

    it "adds repos to list of repos" do
      client.ParseListOfSources(file, url)
      expect(list_of_repos).to_not be_empty
    end

    it "fills also alias for repo" do
      client.ParseListOfSources(file, url)
      expect(list_of_repos.values.first["alias"]).to_not be_nil
    end
  end

  describe "#CreateSource" do
    before do
      allow(Yast::Pkg).to receive(:RepositoryProbe).and_return("RPM-MD")
      allow(Yast::Pkg).to receive(:RepositoryAdd).and_return(1)
    end

    it "probes repo" do
      allow(Yast::Pkg).to receive(:RepositoryProbe).and_return("RPM-MD")

      client.CreateSource("http://yast.rulezz.com", "/", "main", "alias1")
    end

    it "uses passed alias" do
      expect(Yast::Pkg).to receive(:RepositoryAdd)
        .with("enabled" => false, "name" => "main", "base_urls" => ["http://yast.rulezz.com"],
          "prod_dir" => "/", "alias" => "alias1", "type" => "RPM-MD")
        .and_return(1)

      client.CreateSource("http://yast.rulezz.com", "/", "main", "alias1")
    end

    it "uses fallback alias when passed alias" do
      expect(Yast::Pkg).to receive(:RepositoryAdd)
        .with("enabled" => false, "name" => "main", "base_urls" => ["http://yast.rulezz.com"],
          "prod_dir" => "/prod1", "alias" => "yast.rulezz.com", "type" => "RPM-MD")
        .and_return(1)

      client.CreateSource("http://yast.rulezz.com", "/prod1", "main", nil)
    end
  end
end
