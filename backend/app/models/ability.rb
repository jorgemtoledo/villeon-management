class Ability
  include CanCan::Ability

  def initialize(user)
    return unless user

    if user.admin?
      can :manage, :all
    else
      # manager/operator: read-only on Product and Supplier — matches the
      # client's own "QUEM EDITA O QUÊ" legend (only Felipe/admin alters
      # catalog/supplier structure). Each future API block adds this role's
      # real permissions for that resource here, once it exists.
      can %i[index show], Product
      can %i[index show], Supplier
      # Principal/alternate suppliers per product (Bloco 6I.1) — structural
      # catalog data, same read/write split as Product/Supplier themselves:
      # only admin adds/removes/promotes, everyone else only reads.
      can %i[index], ProductSupplier
      can %i[index show], Purchase
      # Registering/editing a purchase (Bloco 6H.1/6H.3) is restricted to
      # manager, per the client's explicit rule (Felipe/admin and Fran/
      # manager only — Luiz, Taris and Eric, all operators, must not). Not
      # sector-scoped: unlike Estoque, a purchase isn't tied to the buyer's
      # own sector.
      can %i[create update], Purchase if user.manager?
      # Read-only reference data for the Product form's unit selects — every
      # role needs it, none of them can manage Unit itself.
      can %i[index], Unit
      # Same reasoning as Unit above, for the Subcategoria filter/select
      # (Bloco Subcategoria) — every role that reads Product also needs the
      # list of codes to filter/display it.
      can %i[index], Subcategory

      # Estoque (Bloco 6G): scoped by the sector-based authorization built in
      # Bloco 6E. Hash conditions (not a block) so the same rule also works
      # with `accessible_by` if a future block needs it, not just `authorize!`.
      if user.has_all_sector_access?
        can %i[index show], ProductStock
        can %i[create update], StockCount
      elsif user.sector_ids.any?
        can %i[index show], ProductStock, product: { sector_id: user.sector_ids }
        can %i[create update], StockCount, product: { sector_id: user.sector_ids }
      end

      # Priority/needs_advance_order (Bloco 6G Parte 4): manager gets this
      # unconditionally, any sector — deliberately NOT gated by
      # has_all_sector_access?/sector_ids like ProductStock/StockCount above,
      # per the client's explicit "Felipe e Fran editam a qualquer momento,
      # independente do setor" rule (a manager without all_sectors set still
      # gets it). Operators only get it within their own sector, and even
      # then only for the *first* save — that lock depends on the row's
      # current data (already set or not), which a static hash condition
      # can't express, so it's enforced in
      # ProductStocksController#update_priority, not here.
      if user.manager?
        can :update_priority, ProductStock
      elsif user.has_all_sector_access?
        can :update_priority, ProductStock
      elsif user.sector_ids.any?
        can :update_priority, ProductStock, product: { sector_id: user.sector_ids }
      end
    end
  end
end
