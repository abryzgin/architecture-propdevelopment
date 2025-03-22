- Развернуть четыре сервиса (в терминах Kubernetes — четыре Pod плюс соответствующие Service-объекты) в одном namespace.
- Присвоить им необходимые метки (labels).
- Настроить сетевые политики (NetworkPolicy), чтобы в кластере разрешить трафик **только** между:
    1. Pod с меткой `role=front-end` и Pod с меткой `role=back-end-api`.
    2. Pod с меткой `role=admin-front-end` и Pod с меткой `role=admin-back-end-api`.
- Запретить взаимодействие всем остальным, создавая «по умолчанию» deny для всех остальных случаев.

## 1. Создание четырёх Pod/Service с нужными метками

Создадим namespace `web-systems`:

```bash
kubectl create namespace web-systems
```

Затем создадим четыре Pod, каждый слушает порт 80 (Nginx):

1. **Front-end**:
   ```bash
   kubectl run front-end-app \
     --image=nginx \
     --labels role=front-end \
     --port 80 \
     --expose \
     -n web-systems
   ```

2. **Back-end-API**:
   ```bash
   kubectl run back-end-api-app \
     --image=nginx \
     --labels role=back-end-api \
     --port 80 \
     --expose \
     -n web-systems
   ```

3. **Admin-front-end**:
   ```bash
   kubectl run admin-front-end-app \
     --image=nginx \
     --labels role=admin-front-end \
     --port 80 \
     --expose \
     -n web-systems
   ```

4. **Admin-back-end-API**:
   ```bash
   kubectl run admin-back-end-api-app \
     --image=nginx \
     --labels role=admin-back-end-api \
     --port 80 \
     --expose \
     -n web-systems
   ```

Проверяем, что поды запустились:

```bash
kubectl get pods -n web-systems -o wide
kubectl get svc -n web-systems
```

Увидим четыре Pod и четыре Service. У каждого Pod/Service есть своя метка role=...

---

## 2. Сетевая политика: запрещаем всё, кроме нужных взаимодействий

Для того чтобы «по умолчанию» запретить трафик между всеми Pod'ами и разрешить только нужные направления (front-end ↔ back-end-api, admin-front-end ↔ admin-back-end-api):

1. Определить «default deny» политику, которая блокирует весь входящий и исходящий трафик, если для Pod включён режим NetworkPolicy.
2. Определить отдельные NetworkPolicy, которые _разрешают_ нужное взаимодействие.

### Файл non-admin-api-allow.yaml

[non-admin-api-allow.yaml](non-admin-api-allow.yaml)

- **default-deny-all**: эта политика говорит «для любого Pod в данном namespace запретить входящий и исходящий трафик», если нет других правил, которые это разрешают.
- **allow-nonadmin-traffic**: снимает запрет для Pod с меткой `role=back-end-api` — им разрешён трафик от/к Pod с меткой `role=front-end`.
- **allow-admin-traffic**: аналогично, но для `role=admin-back-end-api` и `role=admin-front-end`.

Затем применяем:

```bash
kubectl apply -f non-admin-api-allow.yaml
```

**Результат**:
- Pod с `role=front-end` сможет общаться c `back-end-api`; все остальные Pod для него будут недоступны по сети (и наоборот).
- Pod с `role=admin-front-end` сможет общаться c `admin-back-end-api` и обратно.
- Все прочие виды трафика между любыми Pod будут запрещены.

---

## 3. Проверка работы

Можно проверить, например, из одного Pod попытаться `curl`-нуть другой:

```bash
# Зайти в pod front-end-app (role=front-end)
kubectl exec -n web-systems -it front-end-app-<random-id> -- /bin/sh

# Попробовать curl back-end-api
curl http://back-end-api-app:80    # должно сработать (вернётся страница Nginx)

# Попробовать curl admin-back-end-api
curl http://admin-back-end-api-app:80   # должно упасть по таймауту или Connection Refused

exit
```