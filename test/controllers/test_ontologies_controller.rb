require_relative '../test_case'

class TestOntologiesController < TestCase
  def setup
    _set_vars
    _delete
    _create_models
  end

  def teardown
    _set_vars
    _delete
  end

  def _set_vars
    @acronym = "TST"
    @name = "Test Ontology"
    @file_params = {
      name: @name,
      hasOntologyLanguage: "OWL",
      administeredBy: "tim"
    }

    @view_acronym = 'TST_VIEW'
    @view_name = 'Test View of Test Ontology'
    @view_file_params = {
        name: @view_name,
        hasOntologyLanguage: "OWL",
        administeredBy: "tom"
    }
  end

  def _create_models
    _create_user
  end

  def _create_user
    username = "tim"
    test_user = User.new(username: username, email: "#{username}@example.org", password: "password")
    test_user.save if test_user.valid?
    user = test_user.valid? ? test_user : User.find(username)
    user
  end

  def _delete
    _delete_onts
    test_user = User.find("tim")
    test_user.delete unless test_user.nil?
  end

  def test_create_view
    ont = Ontology.new(acronym: @acronym, name: @name, administeredBy: _create_user)
    ont.save
  end

  def _create_onts
    user = _create_user
    ont = Ontology.new(acronym: @acronym, name: @name, administeredBy: user)
    ont.save

    view = Ontology.new(acronym: @view_acronym, name: @view_name, administeredBy: user, viewOf: ont)
    view.save
  end

  def _delete_onts
    view = Ontology.find(@view_acronym)
    view.delete unless view.nil?

    ont = Ontology.find(@acronym)
    ont.delete unless ont.nil?
  end

  def test_all_ontologies
    num_onts_created, created_ont_acronyms = create_ontologies_and_submissions()

    get '/ontologies'
    assert last_response.ok?

    onts = MultiJson.load(last_response.body)
    assert onts.length >= num_onts_created

    all_ont_acronyms = []
    onts.each do |ont|
      all_ont_acronyms << ont["acronym"]
    end

    created_ont_acronyms.each do |acronym|
      assert all_ont_acronyms.include?(acronym)
    end

    delete_ontologies_and_submissions()
  end

  def test_single_ontology
    num_onts_created, created_ont_acronyms = create_ontologies_and_submissions(ont_count: 1)
    ontology = created_ont_acronyms.first
    get "/ontologies/#{ontology}"
    assert last_response.ok?

    ont = MultiJson.load(last_response.body)
    assert ont["acronym"] = ontology

    delete_ontologies_and_submissions()
  end

  def test_create_new_ontology_same_acronym
    _create_onts
    put "/ontologies/#{@acronym}", :name => @name
    assert last_response.status == 409
  end

  def test_create_new_ontology_invalid
    put "/ontologies/#{@acronym}"
    assert last_response.status == 422
    assert MultiJson.load(last_response.body)["errors"]
  end

  def test_patch_ontology
    _create_onts
    name = "Test new name"
    new_name = {name: name}
    patch "/ontologies/#{@acronym}", MultiJson.dump(new_name), "CONTENT_TYPE" => "application/json"
    assert last_response.status == 204

    get "/ontologies/#{@acronym}"
    ont = MultiJson.load(last_response.body)
    assert ont["name"].eql?(name)
  end

  def test_delete_ontology
   # _create_onts
    delete "/ontologies/#{@acronym}"
    assert last_response.status == 204

    get "/ontologies/#{@acronym}"
    assert last_response.status == 404
  end

  def test_download_ontology
    # not implemented yet
  end

  def test_ontology_properties
    # not implemented yet
  end
end
