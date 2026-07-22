class ExpandBillingAndLedger < ActiveRecord::Migration[8.0]
  def up
    add_column :schools, :currency_code, :string, null: false, default: "USD"
    add_column :students, :billing_opening_balance, :decimal, precision: 12, scale: 2, null: false, default: 0

    add_column :invoices, :number, :string
    add_column :invoices, :issued_on, :date
    add_column :invoices, :notes, :text
    add_column :invoices, :cancelled_at, :datetime
    add_reference :invoices, :cancelled_by, foreign_key: { to_table: :users }
    execute "UPDATE invoices SET number = CONCAT('INV-', LPAD(id, 8, '0')), issued_on = DATE(created_at) WHERE number IS NULL"
    change_column_null :invoices, :number, false
    change_column_null :invoices, :issued_on, false
    add_index :invoices, :number, unique: true

    add_column :payments, :receipt_number, :string
    add_reference :payments, :recorded_by, foreign_key: { to_table: :users }
    add_column :payments, :reversed_at, :datetime
    add_reference :payments, :reversed_by, foreign_key: { to_table: :users }
    add_column :payments, :reversal_reason, :text
    execute "UPDATE payments SET receipt_number = CONCAT('RCT-', LPAD(id, 8, '0')) WHERE receipt_number IS NULL"
    change_column_null :payments, :receipt_number, false
    add_index :payments, :receipt_number, unique: true

    create_table :invoice_line_items do |t|
      t.references :invoice, null: false, foreign_key: true
      t.string :description, null: false
      t.integer :category, null: false, default: 0
      t.decimal :quantity, precision: 10, scale: 2, null: false, default: 1
      t.decimal :unit_amount, precision: 12, scale: 2, null: false
      t.timestamps
    end

    create_table :billing_adjustments do |t|
      t.references :invoice, null: false, foreign_key: true
      t.integer :kind, null: false
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.string :reason, null: false
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.references :approved_by, null: false, foreign_key: { to_table: :users }
      t.timestamps
    end

    create_table :payment_installments do |t|
      t.references :invoice, null: false, foreign_key: true
      t.string :name, null: false
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.date :due_on, null: false
      t.integer :status, null: false, default: 0
      t.timestamps
    end

    add_index :payment_installments, %i[invoice_id due_on]

    # Preserve every existing invoice as a meaningful line item.
    execute <<~SQL.squish
      INSERT INTO invoice_line_items (invoice_id, description, category, quantity, unit_amount, created_at, updated_at)
      SELECT invoices.id, fee_structures.name, 0, 1, invoices.amount, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
      FROM invoices INNER JOIN fee_structures ON fee_structures.id = invoices.fee_structure_id
    SQL
  end

  def down
    drop_table :payment_installments
    drop_table :billing_adjustments
    drop_table :invoice_line_items
    remove_index :payments, :receipt_number
    remove_reference :payments, :reversed_by, foreign_key: { to_table: :users }
    remove_column :payments, :reversed_at
    remove_column :payments, :reversal_reason
    remove_reference :payments, :recorded_by, foreign_key: { to_table: :users }
    remove_column :payments, :receipt_number
    remove_index :invoices, :number
    remove_reference :invoices, :cancelled_by, foreign_key: { to_table: :users }
    remove_column :invoices, :cancelled_at
    remove_column :invoices, :notes
    remove_column :invoices, :issued_on
    remove_column :invoices, :number
    remove_column :students, :billing_opening_balance
    remove_column :schools, :currency_code
  end
end
