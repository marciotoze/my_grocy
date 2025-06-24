alias MyGrocy.Products
alias MyGrocy.Repo

Repo.delete_all(Products.Product)

Products.create_product(%{
  name: "Arroz Integral",
  description: "Em pacotes de 1kg",
  quantity: 10,
  min_quantity: 1
})

Products.create_product(%{
  name: "Feijão",
  description: "Em pacotes de 1kg",
  quantity: 5,
  min_quantity: 10
})

Products.create_product(%{
  name: "Macarrão",
  description: "Em pacotes de 500g",
  quantity: 20,
  min_quantity: 5
})

Products.create_product(%{
  name: "Azeite de Oliva",
  description: "Em garrafas de 500ml",
  quantity: 15,
  min_quantity: 2
})

Products.create_product(%{
  name: "Sal",
  description: "Em pacotes de 1kg",
  quantity: 25,
  min_quantity: 3
})

Products.create_product(%{
  name: "Açúcar",
  description: "Em pacotes de 1kg",
  quantity: 30,
  min_quantity: 4
})
