using ShopAlgorithms

n = 4
m = 2
n_i = [6, 6, 6, 6]
p = [[9, 6, 9, 6, 7, 7], [8, 6, 8, 10, 8, 9], [6, 7, 6, 8, 8, 10], [6, 8, 6, 8, 9, 8]]
μ = [[1, 2, 2, 2, 1, 1], [1, 2, 2, 2, 1, 1], [1, 1, 2, 1, 1, 1], [1, 2, 1, 2, 2, 2]]

instance = ShopInstances.JobShopInstance(n, m, n_i, p, μ; name="test")
result = Algorithms.generate_active_schedules(instance)
