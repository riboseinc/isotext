require "spec_helper"
require "nokogiri"

RSpec.describe IsoDoc do
  it "processes IsoXML metadata" do
    c = IsoDoc::Convert.new({})
    arr = c.convert_init(<<~"INPUT", "test", false)
    <iso-standard xmlns="http://riboseinc.com/isoxml">
    INPUT
  expect(Hash[c.info(Nokogiri::XML(<<~"INPUT"), nil).sort]).to be_equivalent_to <<~"OUTPUT"
    <iso-standard xmlns="http://riboseinc.com/isoxml">
    <bibdata type="international-standard">
  <title>The Incredible Mr Ripley</title>
  <title language="en">Cereals and pulses</title>
  <source>URL A</source>
  <source type="html">URL B</source>
  <source type="xml">URL C</source>
  <source type="pdf">URL D</source>
  <source type="doc">URL E</source>
  <docidentifier>17301-1</docidentifier>
  <docnumber>17301</docnumber>
  <date type="published"><on>2011</on></date>
  <date type="accessed"><on>2012</on></date>
  <date type="created"><from>2010</from><to>2011</to></date>
  <date type="activated"><on>2013</on></date>
  <date type="obsoleted"><on>2014</on></date>
  <contributor>
    <role type="author"/>
    <organization>
      <abbreviation>ISO</abbreviation>
    </organization>
  </contributor>
  <contributor>
    <role type="publisher"/>
    <organization>
      <abbreviation>ISO</abbreviation>
    </organization>
  </contributor>
  <language>en</language>
  <script>Latn</script>
  <status>Committee Draft</status>
  <copyright>
    <from>2016</from>
    <owner>
      <organization>
        <abbreviation>ISO</abbreviation>
      </organization>
    </owner>
  </copyright>
  <editorialgroup>
    <technical-committee number="34">Food products</technical-committee>
    <subcommittee number="4">Cereals and pulses</subcommittee>
    <workgroup number="3">Rice Group</workgroup>
    <secretariat>GB</secretariat>
  </editorialgroup>
</bibdata><version>
  <edition>2</edition>
  <revision-date>2016-05-01</revision-date>
  <draft>0.4</draft>
</version>
</iso-standard>
INPUT
{:accesseddate=>"2012", :activateddate=>"2013", :agency=>"ISO", :confirmeddate=>"XXX", :createddate=>"2010&ndash;2011", :doc=>"URL E", :docnumber=>"17301-1", :doctitle=>"Cereals and pulses", :doctype=>"International Standard", :docyear=>"2016", :draft=>"0.4", :draftinfo=>" (draft 0.4, 2016-05-01)", :editorialgroup=>["TC 34", "SC 4", "WG 3"], :html=>"URL B", :ics=>"XXX", :implementeddate=>"XXX", :issueddate=>"XXX", :obsoleteddate=>"2014", :obsoletes=>nil, :obsoletes_part=>nil, :pdf=>"URL D", :publisheddate=>"2011", :receiveddate=>"XXX", :revdate=>"2016-05-01", :sc=>"SC 4", :secretariat=>"GB", :status=>"Committee draft", :tc=>"TC 34", :updateddate=>"XXX", :url=>"URL A", :wg=>"WG 3", :xml=>"URL C"}
OUTPUT
  end

  it "processes IsoXML metadata" do
        c = IsoDoc::Convert.new({})
    arr = c.convert_init(<<~"INPUT", "test", false)
    <iso-standard xmlns="http://riboseinc.com/isoxml">
    INPUT
  expect(Hash[c.info(Nokogiri::XML(<<~"INPUT"), nil).sort]).to be_equivalent_to <<~"OUTPUT"
    <iso-standard xmlns="http://riboseinc.com/isoxml">
    <bibdata type="international-standard">
  <title language="fr" format="text/plain">Céréales et légumineuses</ti>
  <title language="en" format="text/plain">Cereals and pulses</title>
  <docidentifier>17301-1-3</docidentifier>
  <docnumber>17301</docnumber>
  <contributor>
    <role type="author"/>
    <organization>
      <name>ISO</name>
    </organization>
  </contributor>
  <contributor>
    <role type="publisher"/>
    <organization>
      <abbreviation>ISO</abbreviation>
     </organization>
  </contributor>
  <contributor>
    <role type="publisher"/>
    <organization>
      <abbreviation>IEC</abbreviation>
    </organization>
  </contributor>
  <language>en</language>
  <script>Latn</script>
  <status>Published</status>
  <copyright>
    <from>2016</from>
    <owner>
      <organization>
        <name>International Organization for Standardization</name>
      </organization>
    </owner>
  </copyright>
  <relation type="obsoletes">
    <locality type="clause"><referenceFrom>3.1</referenceFrom></locality>
    <docidentifier>IEC 8121</docidentifier>
  </relation>
  <editorialgroup>
    <technical-committee number="34" type="ABC">Food products</technical-committee>
    <subcommittee number="4" type="DEF">Cereals and pulses</subcommittee>
    <workgroup number="3" type="GHI">Rice Group</workgroup>
  </editorialgroup>
  <ics><code>1.2.3</code></ics>
  <ics><code>1.2.3</code></ics>
</bibdata><version>
  <edition>2</edition>
  <revision-date>2016-05-01</revision-date>
  <draft>12</draft>
</version>
</iso-standard>
INPUT
{:accesseddate=>"XXX", :agency=>"ISO/IEC", :confirmeddate=>"XXX", :createddate=>"XXX", :docnumber=>"17301-1-3", :doctitle=>"Cereals and pulses", :doctype=>"International Standard", :docyear=>"2016", :draft=>"12", :draftinfo=>" (draft 12, 2016-05-01)", :editorialgroup=>["ABC 34", "DEF 4", "GHI 3"], :ics=>"1.2.3, 1.2.3", :implementeddate=>"XXX", :issueddate=>"XXX", :obsoleteddate=>"XXX", :obsoletes=>"IEC 8121", :obsoletes_part=>"3.1", :publisheddate=>"XXX", :receiveddate=>"XXX", :revdate=>"2016-05-01", :sc=>"DEF 4", :secretariat=>"XXXX", :status=>"Published", :tc=>"ABC 34", :updateddate=>"XXX", :wg=>"GHI 3"}
OUTPUT
  end

end
