namespace :deploy do
  desc 'prepare git tree so we can tag on successful deployment'
  before :deploy, :prepare_tree do
    run_locally do
      if ENV['NO_DEPLOYTAGS'] || fetch(:no_deploytags, false)
        info "[deploytags] Skipping deploytags"
      else
        branch = fetch(:branch, false)
        stage = fetch(:stage, false)

        unless branch && stage
          error 'capistrano-deploytags requires that :branch and :stage be defined'
          raise 'define :branch and :stage'
        end

        strategy.git "fetch #{fetch(:git_remote, 'origin')}"

        diff_output = capture :git, "diff #{branch} --shortstat"

        unless diff_output.empty?
          error "Whoa there, partner. Dirty trees can't deploy. Git yerself clean first"
          raise 'Dirty git tree'
        end

        strategy.git "checkout #{branch}"
        info "Pulling from #{branch}"
        strategy.git "pull #{fetch(:git_remote, 'origin')} #{branch}"
      end
    end
  end

  desc 'add git tags for each successful deployment'
  after :cleanup, :tagdeploy do
    run_locally do
      if ENV['NO_DEPLOYTAGS'] || fetch(:no_deploytags, false)
        info "[deploytags] Skipping deploytags"
      else
        original_tag_name = CapistranoDeploytags::Helper.git_tag_for(fetch(:stage))
        tag_name = fetch(:tag_release_name)
        latest_revision = fetch(:current_revision)
        #commit_message = CapistranoDeploytags::Helper.commit_message(latest_revision, fetch(:stage))
        commit_message = original_tag_name
        strategy.git "tag -a #{tag_name} -m \"#{commit_message}\" #{latest_revision}"
        strategy.git "push #{fetch(:git_remote, 'origin')} #{tag_name}"

        info "[cap-deploy-tagger] Tagged #{latest_revision} with #{tag_name}"
      end
    end
  end
end
