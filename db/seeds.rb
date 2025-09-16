Phase.create(name: 'Phase 1', price: 100, ticket_amount: 100, start_date: Date.today, end_date: Date.today + 1.year)
Phase.create(name: 'Phase 2', price: 200, ticket_amount: 200, start_date: Date.today, end_date: Date.today + 1.year)
Phase.create(name: 'Phase 3', price: 300, ticket_amount: 300, start_date: Date.today, end_date: Date.today + 1.year)

Cupon.create(name: 'Cupon 1', type: 'Cupon', active: true, value: 10, amount: 100, end_date: Date.today + 1.year)
Cupon.create(name: 'Cupon 2', type: 'Cupon', active: true, value: 20, amount: 200, end_date: Date.today + 1.year)
Cupon.create(name: 'Cupon 3', type: 'Cupon', active: true, value: 30, amount: 300, end_date: Date.today + 1.year)

Ticket.create(phase: Phase.first, cupon: Cupon.first, client_name: 'John Doe', client_email: 'john.doe@example.com', payment_id: '1234567890', price: 100)
Ticket.create(phase: Phase.second, cupon: Cupon.second, client_name: 'Jane Doe', client_email: 'jane.doe@example.com', payment_id: '1234567890', price: 200)
Ticket.create(phase: Phase.third, cupon: Cupon.third, client_name: 'Jim Doe', client_email: 'jim.doe@example.com', payment_id: '1234567890', price: 300)
Ticket.create(cupon: Cupon.first, client_name: 'John Doe', client_email: 'john.doe@example.com', payment_id: '1234567890', price: 100)