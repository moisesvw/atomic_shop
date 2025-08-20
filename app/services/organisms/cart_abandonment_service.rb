# frozen_string_literal: true

module Services
  module Organisms
    # 🦠 Organism Service: Cart Abandonment Service
    #
    # This organism service handles cart abandonment detection, analysis,
    # and recovery workflows. It demonstrates how atomic design can be
    # applied to complex business intelligence and marketing automation
    # scenarios by composing multiple molecule services.
    #
    # Atomic Design Principles:
    # - Orchestrates Multiple Molecules: Uses CartValidationService, CartTotalsService, etc.
    # - Business Intelligence Workflow: Analyzes cart abandonment patterns
    # - Marketing Automation: Triggers recovery campaigns
    # - Data Analytics: Provides insights for business optimization
    #
    # Usage Examples:
    #   service = Services::Organisms::CartAbandonmentService.new
    #   result = service.detect_abandoned_carts
    #   result = service.analyze_abandonment_reasons(cart)
    #   result = service.create_recovery_campaign(abandoned_carts)
    class CartAbandonmentService
      def initialize(abandonment_threshold: 1.hour)
        @abandonment_threshold = abandonment_threshold

        # Initialize atomic services
        @cart_finder = Services::Atoms::CartFinder.new
        @price_calculator = Services::Atoms::PriceCalculator.new
      end

      # 🎯 Detect abandoned carts
      #
      # @param since [Time] Look for carts abandoned since this time
      # @param limit [Integer] Maximum number of carts to analyze
      # @return [Hash] Abandoned cart detection result
      def detect_abandoned_carts(since: @abandonment_threshold.ago, limit: 100)
        # Find abandoned carts
        abandoned_carts = @cart_finder.abandoned_carts(since: since, limit: limit)

        return success("No abandoned carts found", { abandoned_carts: [] }) if abandoned_carts.empty?

        # Analyze each abandoned cart
        analyzed_carts = abandoned_carts.map do |cart|
          analyze_abandoned_cart(cart)
        end

        # Calculate abandonment statistics
        stats = calculate_abandonment_statistics(analyzed_carts)

        success("Abandoned carts detected", {
          count: analyzed_carts.length,
          abandoned_carts: analyzed_carts,
          statistics: stats,
          recommendations: generate_recovery_recommendations(analyzed_carts)
        })
      rescue StandardError => e
        failure("Error detecting abandoned carts: #{e.message}")
      end

      # 🎯 Analyze abandonment reasons for a specific cart
      #
      # @param cart [Cart] The abandoned cart to analyze
      # @return [Hash] Abandonment analysis result
      def analyze_abandonment_reasons(cart)
        return failure("Cart is required") unless cart

        analysis = {
          cart_id: cart.id,
          abandonment_stage: determine_abandonment_stage(cart),
          potential_reasons: identify_potential_reasons(cart),
          cart_value: analyze_cart_value(cart),
          user_behavior: analyze_user_behavior(cart),
          recovery_potential: assess_recovery_potential(cart)
        }

        success("Abandonment analysis completed", analysis)
      rescue StandardError => e
        failure("Error analyzing abandonment reasons: #{e.message}")
      end

      # 🎯 Create recovery campaign for abandoned carts
      #
      # @param abandoned_carts [Array<Cart>] Carts to target for recovery
      # @param campaign_type [String] Type of recovery campaign
      # @return [Hash] Recovery campaign creation result
      def create_recovery_campaign(abandoned_carts, campaign_type: "email")
        return failure("No carts provided") if abandoned_carts.empty?

        # Segment carts by recovery potential
        segmented_carts = segment_carts_for_recovery(abandoned_carts)

        # Create campaign strategies for each segment
        campaigns = segmented_carts.map do |segment, carts|
          create_segment_campaign(segment, carts, campaign_type)
        end

        # Calculate expected recovery metrics
        expected_metrics = calculate_expected_recovery(campaigns)

        success("Recovery campaign created", {
          campaign_count: campaigns.length,
          targeted_carts: abandoned_carts.length,
          campaigns: campaigns,
          expected_metrics: expected_metrics
        })
      rescue StandardError => e
        failure("Error creating recovery campaign: #{e.message}")
      end

      # 🎯 Generate abandonment prevention insights
      #
      # @param time_period [Range] Time period to analyze
      # @return [Hash] Prevention insights result
      def generate_prevention_insights(time_period: 30.days.ago..Time.current)
        # Analyze abandonment patterns over time period
        all_carts = Cart.where(created_at: time_period)
        abandoned_carts = all_carts.where(status: "abandoned")
        completed_carts = all_carts.where(status: "completed")

        # Calculate key metrics
        abandonment_rate = calculate_abandonment_rate(all_carts, abandoned_carts)
        common_reasons = identify_common_abandonment_reasons(abandoned_carts)
        stage_analysis = analyze_abandonment_by_stage(abandoned_carts)
        value_analysis = analyze_abandonment_by_value(abandoned_carts)

        insights = {
          time_period: {
            start_date: time_period.begin,
            end_date: time_period.end
          },
          metrics: {
            total_carts: all_carts.count,
            abandoned_carts: abandoned_carts.count,
            completed_carts: completed_carts.count,
            abandonment_rate: abandonment_rate
          },
          analysis: {
            common_reasons: common_reasons,
            stage_breakdown: stage_analysis,
            value_breakdown: value_analysis
          },
          recommendations: generate_prevention_recommendations(common_reasons, stage_analysis)
        }

        success("Prevention insights generated", insights)
      rescue StandardError => e
        failure("Error generating prevention insights: #{e.message}")
      end

      # 🎯 Track recovery campaign performance
      #
      # @param campaign_id [String] Campaign identifier
      # @return [Hash] Campaign performance result
      def track_recovery_performance(campaign_id)
        # In a real app, this would track actual campaign performance
        # For now, we'll simulate performance metrics

        performance = {
          campaign_id: campaign_id,
          sent_count: 150,
          opened_count: 45,
          clicked_count: 12,
          recovered_count: 8,
          revenue_recovered_cents: 45600, # $456.00
          metrics: {
            open_rate: 30.0,
            click_rate: 8.0,
            recovery_rate: 5.3,
            revenue_per_email: @price_calculator.format_price(304) # $3.04
          }
        }

        success("Recovery performance tracked", performance)
      rescue StandardError => e
        failure("Error tracking recovery performance: #{e.message}")
      end

      private

      # 🔧 Analyze individual abandoned cart
      def analyze_abandoned_cart(cart)
        totals_service = Services::Molecules::CartTotalsService.new(cart: cart)
        totals_result = totals_service.calculate_totals

        {
          cart_id: cart.id,
          user_id: cart.user_id,
          session_id: cart.session_id,
          created_at: cart.created_at,
          last_activity: cart.updated_at,
          abandonment_duration: time_since_abandonment(cart),
          cart_value_cents: totals_result[:success] ? totals_result[:data][:total_cents] : 0,
          cart_value: totals_result[:success] ? totals_result[:data][:total] : "$0.00",
          item_count: cart.total_items,
          abandonment_stage: determine_abandonment_stage(cart),
          recovery_potential: assess_recovery_potential(cart)
        }
      end

      # 🔧 Determine abandonment stage
      def determine_abandonment_stage(cart)
        # Analyze cart state to determine where user abandoned
        if cart.cart_items.empty?
          "browsing"
        elsif cart.total_items == 1
          "single_item"
        elsif cart.total_items > 1
          "multiple_items"
        else
          "unknown"
        end
      end

      # 🔧 Identify potential abandonment reasons
      def identify_potential_reasons(cart)
        reasons = []

        # High cart value might indicate price sensitivity
        if cart.total_price_cents > 20000 # $200+
          reasons << "high_cart_value"
        end

        # Many items might indicate decision fatigue
        if cart.total_items > 10
          reasons << "decision_fatigue"
        end

        # Check for out-of-stock items
        validation_service = Services::Molecules::CartValidationService.new(cart: cart)
        validation_result = validation_service.validate_cart_state
        
        unless validation_result[:success]
          reasons << "inventory_issues"
        end

        # Time-based reasons
        abandonment_duration = time_since_abandonment(cart)
        if abandonment_duration > 1.day
          reasons << "long_consideration"
        elsif abandonment_duration < 5.minutes
          reasons << "quick_abandonment"
        end

        reasons
      end

      # 🔧 Analyze cart value characteristics
      def analyze_cart_value(cart)
        totals_service = Services::Molecules::CartTotalsService.new(cart: cart)
        totals_result = totals_service.calculate_totals

        return {} unless totals_result[:success]

        totals = totals_result[:data]
        
        {
          subtotal_cents: totals[:subtotal_cents],
          subtotal: totals[:subtotal],
          item_count: cart.total_items,
          average_item_value_cents: cart.total_items > 0 ? totals[:subtotal_cents] / cart.total_items : 0,
          value_category: categorize_cart_value(totals[:subtotal_cents])
        }
      end

      # 🔧 Analyze user behavior patterns
      def analyze_user_behavior(cart)
        {
          user_type: cart.user_id ? "registered" : "guest",
          session_duration: calculate_session_duration(cart),
          return_visitor: cart.user_id ? check_return_visitor(cart.user_id) : false,
          previous_purchases: cart.user_id ? count_previous_purchases(cart.user_id) : 0
        }
      end

      # 🔧 Assess recovery potential
      def assess_recovery_potential(cart)
        score = 0
        factors = []

        # User factors
        if cart.user_id
          score += 30
          factors << "registered_user"
        end

        # Cart value factors
        if cart.total_price_cents > 5000 # $50+
          score += 20
          factors << "significant_value"
        end

        # Timing factors
        abandonment_duration = time_since_abandonment(cart)
        if abandonment_duration < 24.hours
          score += 25
          factors << "recent_abandonment"
        end

        # Item factors
        if cart.total_items > 1
          score += 15
          factors << "multiple_items"
        end

        {
          score: score,
          level: categorize_recovery_potential(score),
          factors: factors
        }
      end

      # 🔧 Calculate abandonment statistics
      def calculate_abandonment_statistics(analyzed_carts)
        return {} if analyzed_carts.empty?

        total_value_cents = analyzed_carts.sum { |cart| cart[:cart_value_cents] }
        
        {
          total_abandoned_value_cents: total_value_cents,
          total_abandoned_value: @price_calculator.format_price(total_value_cents),
          average_cart_value_cents: total_value_cents / analyzed_carts.length,
          average_cart_value: @price_calculator.format_price(total_value_cents / analyzed_carts.length),
          high_value_carts: analyzed_carts.count { |cart| cart[:cart_value_cents] > 10000 },
          recovery_potential_distribution: {
            high: analyzed_carts.count { |cart| cart[:recovery_potential][:level] == "high" },
            medium: analyzed_carts.count { |cart| cart[:recovery_potential][:level] == "medium" },
            low: analyzed_carts.count { |cart| cart[:recovery_potential][:level] == "low" }
          }
        }
      end

      # 🔧 Generate recovery recommendations
      def generate_recovery_recommendations(analyzed_carts)
        recommendations = []

        high_value_carts = analyzed_carts.select { |cart| cart[:cart_value_cents] > 10000 }
        if high_value_carts.any?
          recommendations << {
            type: "high_value_recovery",
            priority: "high",
            description: "Target #{high_value_carts.length} high-value carts with personalized offers",
            potential_revenue: @price_calculator.format_price(high_value_carts.sum { |cart| cart[:cart_value_cents] })
          }
        end

        recent_carts = analyzed_carts.select { |cart| cart[:abandonment_duration] < 24.hours }
        if recent_carts.any?
          recommendations << {
            type: "immediate_recovery",
            priority: "medium",
            description: "Send immediate recovery emails to #{recent_carts.length} recently abandoned carts",
            timing: "within 2 hours"
          }
        end

        recommendations
      end

      # 🔧 Segment carts for recovery campaigns
      def segment_carts_for_recovery(abandoned_carts)
        segments = {
          high_value: [],
          recent: [],
          registered_users: [],
          guests: []
        }

        abandoned_carts.each do |cart|
          analysis = analyze_abandoned_cart(cart)
          
          segments[:high_value] << cart if analysis[:cart_value_cents] > 10000
          segments[:recent] << cart if analysis[:abandonment_duration] < 24.hours
          segments[:registered_users] << cart if cart.user_id
          segments[:guests] << cart unless cart.user_id
        end

        segments.reject { |_, carts| carts.empty? }
      end

      # 🔧 Create campaign for specific segment
      def create_segment_campaign(segment, carts, campaign_type)
        {
          segment: segment,
          cart_count: carts.length,
          campaign_type: campaign_type,
          strategy: get_segment_strategy(segment),
          timing: get_segment_timing(segment),
          expected_recovery_rate: get_expected_recovery_rate(segment)
        }
      end

      # 🔧 Helper methods for analysis
      def time_since_abandonment(cart)
        Time.current - cart.updated_at
      end

      def categorize_cart_value(value_cents)
        case value_cents
        when 0..2500 then "low"
        when 2501..10000 then "medium"
        when 10001..25000 then "high"
        else "premium"
        end
      end

      def categorize_recovery_potential(score)
        case score
        when 0..30 then "low"
        when 31..60 then "medium"
        else "high"
        end
      end

      def calculate_session_duration(cart)
        # Placeholder - would calculate from actual session data
        "15 minutes"
      end

      def check_return_visitor(user_id)
        # Placeholder - would check user's visit history
        true
      end

      def count_previous_purchases(user_id)
        # Placeholder - would count user's order history
        2
      end

      def calculate_abandonment_rate(all_carts, abandoned_carts)
        return 0.0 if all_carts.count == 0
        (abandoned_carts.count.to_f / all_carts.count * 100).round(1)
      end

      def identify_common_abandonment_reasons(abandoned_carts)
        # Placeholder - would analyze actual abandonment data
        [
          { reason: "high_shipping_cost", percentage: 35.2 },
          { reason: "unexpected_fees", percentage: 28.7 },
          { reason: "complex_checkout", percentage: 18.9 },
          { reason: "security_concerns", percentage: 12.1 },
          { reason: "out_of_stock", percentage: 5.1 }
        ]
      end

      def analyze_abandonment_by_stage(abandoned_carts)
        # Placeholder - would analyze actual stage data
        {
          cart_page: 45.2,
          shipping_info: 28.3,
          payment_info: 18.7,
          review_order: 7.8
        }
      end

      def analyze_abandonment_by_value(abandoned_carts)
        # Placeholder - would analyze actual value data
        {
          "0-25": 15.2,
          "25-50": 28.7,
          "50-100": 32.1,
          "100-200": 18.3,
          "200+": 5.7
        }
      end

      def generate_prevention_recommendations(common_reasons, stage_analysis)
        [
          "Implement transparent shipping cost calculator",
          "Simplify checkout process",
          "Add security badges and trust signals",
          "Implement exit-intent popups with offers",
          "Optimize mobile checkout experience"
        ]
      end

      def get_segment_strategy(segment)
        strategies = {
          high_value: "Personalized discount offer",
          recent: "Gentle reminder with urgency",
          registered_users: "Account-based personalization",
          guests: "Registration incentive"
        }
        strategies[segment] || "Standard recovery email"
      end

      def get_segment_timing(segment)
        timings = {
          high_value: "24 hours",
          recent: "2 hours",
          registered_users: "12 hours",
          guests: "6 hours"
        }
        timings[segment] || "24 hours"
      end

      def get_expected_recovery_rate(segment)
        rates = {
          high_value: 15.2,
          recent: 12.8,
          registered_users: 8.5,
          guests: 4.2
        }
        rates[segment] || 6.0
      end

      def calculate_expected_recovery(campaigns)
        total_carts = campaigns.sum { |campaign| campaign[:cart_count] }
        weighted_recovery_rate = campaigns.sum { |campaign| 
          campaign[:cart_count] * campaign[:expected_recovery_rate] 
        } / total_carts.to_f

        {
          total_targeted_carts: total_carts,
          expected_recovery_rate: weighted_recovery_rate.round(1),
          expected_recovered_carts: (total_carts * weighted_recovery_rate / 100).round
        }
      end

      # 🔧 Success response helper
      def success(message, data = {})
        {
          success: true,
          message: message,
          data: data
        }
      end

      # 🔧 Failure response helper
      def failure(message, data = {})
        {
          success: false,
          message: message,
          data: data
        }
      end
    end
  end
end
