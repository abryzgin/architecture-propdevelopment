## 1. Таблица ролей

В качестве примера берём три роли:

| Роль            | Права роли                                                                                                                                                                               | Группы пользователей                                                                   |
|:----------------|:-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|:----------------------------------------------------------------------------------------|
| **viewer**      | Чтение (get, list, watch) всех основных ресурсов (Pods, Services, Deployments, ReplicaSets, StatefulSets и т. п.)                                                                        | «Наблюдатели» (например, младшие операторы, QA, пользователи, которым нужен лишь просмотр) |
| **cluster-operator** | Создание/редактирование/удаление (create, update, patch, delete) основных ресурсов (Pods, Deployments, Services и т. п.), но без доступа к секретам, критичным системным ресурсам (Nodes) | «DevOps/Операторы», которые занимаются развёртыванием сервисов, но не должны видеть секреты |
| **privileged**  | Полный доступ (включая работу с Secret, ConfigMap, Node, API группой RBAC, просмотрами логов на кластере и т. п.), а также все действия (verbs: ["*"]) на ресурсах кластера              | «Администраторы» кластера, «Служба безопасности»; имеют право на все операции, в т.ч. просмотр секретов |

---
## 2. Файл 1: Создание пользователей

[01-create-users.sh](01-create-users.sh)

Запуск:

```bash
chmod +x 01-create-users.sh
./01-create-users.sh
```

## 3. Файл 2: Создание ролей

Ниже YAML-манифест, который создаст три **ClusterRole**: `viewer`, `cluster-operator` и `privileged`.

- **viewer**  
  Чтение (get, list, watch) основных ресурсов (Pods, Deployments, Services и т. д.).
- **cluster-operator**  
  Создание/редактирование/удаление (create, update, patch, delete) основных ресурсов, но без секретов и узлов.
- **privileged**  
  Полный доступ ко всем ресурсам кластера (включая Secret, RBAC, Node и прочее).

**02-create-roles.yaml**:

[create-roles.yaml](create-roles.yaml)

Применить:

```bash
kubectl apply -f 02-create-roles.yaml
```

---

## 4. Файл 3: Привязка пользователей к ролям

Чтобы учётные записи (SA) «developer» и «viewer» реально получили права, им нужно дать **ClusterRoleBinding** (при условии, что роли у нас именно ClusterRole).

**03-create-rolebindings.yaml**:

[03-create-rolebindings.yaml](03-create-rolebindings.yaml)

Применение:

```bash
kubectl apply -f 03-create-rolebindings.yaml
```

Теперь:
- ServiceAccount **viewer** может только читать (get/list/watch) те ресурсы, которые перечислены в роли `viewer`.
- ServiceAccount **developer** может, кроме чтения, создавать/обновлять/удалять (create, update, patch, delete) вышеуказанные ресурсы, но не секреты.
- ServiceAccount **admin-user** получит полный доступ ко всему в кластере.
