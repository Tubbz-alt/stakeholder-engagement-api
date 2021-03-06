module Api
  module V1
    class EngagementsController < Api::V1::ApiController
      def index
        @engagements = helpers.paginate(
          Engagement.all
            .order(helpers.to_activerecord_order_clause(params[:sort], Engagement))
        )
        authorize @engagements
        respond_with @engagements,  include: [:stakeholder, :recorded_by]
      end

      def show
        @engagement = Engagement.find(params[:id])
        authorize @engagement
        respond_with @engagement,  include: [:stakeholder, :recorded_by]
      end

      def create
        @engagement = Engagement.new(engagement_params)
        authorize @engagement
        @engagement.save!
        response.headers['Location'] = url_for([:api, :v1, @engagement])
        update_relationships_if_needed(@engagement)
        respond_with  @engagement,  status: :created,
                                      include: [:stakeholder, :recorded_by]
      end

      def update
        @engagement = Engagement.find(params[:id])
        authorize @engagement
        @engagement.update!(engagement_params)
        update_relationships_if_needed(@engagement)
        respond_with  @engagement, status: :ok,
                                     include: [:stakeholder, :recorded_by]
      end

      def destroy
        @engagement = Engagement.find(params[:id])
        authorize @engagement
        @engagement.destroy!
        render jsonapi: nil, status: :no_content
      end

      private

      def update_relationships_if_needed(engagement)
        if pa_params = relationship_params.try(:[], :policy_areas)
          engagement.policy_area_ids = pa_params[:data].map{|e| e[:id]}
        end
      end

      def relationship_params(opts = params)
        opts.require(:data).permit(
          relationships: {
            policy_areas: {
              data: [:type, :id]
            }
          }
        ).try(:[], :relationships)
      end

      def engagement_params(opts = params)
        opts.require(:data).permit(
          attributes: [
            :anonymous,
            :contact_date,
            :contact_made,
            :summary,
            :notes,
            :next_steps,
            :escalated,
            :email_receipt,
            :next_planned_contact,
            :stakeholder_id,
            :recorded_by_id,
            :created_at,
            :updated_at
          ]
        )
      end
    end
  end
end
