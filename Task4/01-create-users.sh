#!/usr/bin/env bash

# Создаём namespace для эксплуатационных пользователей (если ещё не существует)
kubectl create namespace ops || echo "Namespace 'ops' уже существует"

# Создаём ServiceAccount для разработчиков (cluster-operator)
kubectl create serviceaccount developer -n ops

# Создаём ServiceAccount для пользователей «только чтение» (viewer)
kubectl create serviceaccount viewer -n ops

# (Опционально) Создаём ServiceAccount для администраторов (полный доступ)
# kubectl create serviceaccount admin-user -n ops

echo "ServiceAccounts 'developer' и 'viewer' успешно созданы в namespace 'ops'."
