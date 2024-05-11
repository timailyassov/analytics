--TASK 1
/*Для каждого дня, представленного в таблицах user_actions и courier_actions, рассчитайте следующие показатели:

Число новых пользователей.
Число новых курьеров.
Общее число пользователей на текущий день.
Общее число курьеров на текущий день.*/

with time_user as (SELECT count(user_id) users_count,
                          min_date FROM(SELECT user_id,
                                        min(date(time)) min_date
                                 FROM   user_actions
                                 GROUP BY 1) t
                   GROUP BY 2), time_courier as (SELECT count(courier_id) couriers_count,
                                     min_date FROM(SELECT courier_id,
                                                   min(date(time)) min_date
                                            FROM   courier_actions
                                            GROUP BY 1) t1
                              GROUP BY 2)
SELECT min_date as date,
       users_count new_users,
       couriers_count new_couriers,
       sum(users_count) OVER (ORDER BY min_date)::int total_users,
       sum(couriers_count) OVER (ORDER BY min_date)::int total_couriers
FROM   (SELECT users_count,
               min_date,
               couriers_count
        FROM   time_user
            INNER JOIN time_courier using(min_date)) t2
ORDER BY 1


--TASK 2
/*Дополните запрос из предыдущего задания и теперь для каждого дня, представленного в таблицах user_actions и courier_actions, дополнительно рассчитайте следующие показатели:

Прирост числа новых пользователей.
Прирост числа новых курьеров.
Прирост общего числа пользователей.
Прирост общего числа курьеров.*/

with time_user as (SELECT count(user_id) users_count,
                          min_date FROM(SELECT user_id,
                                        min(date(time)) min_date
                                 FROM   user_actions
                                 GROUP BY 1) t
                   GROUP BY 2), time_courier as (SELECT count(courier_id) couriers_count,
                                     min_date FROM(SELECT courier_id,
                                                   min(date(time)) min_date
                                            FROM   courier_actions
                                            GROUP BY 1) t1
                              GROUP BY 2)
SELECT date,
       new_users,
       new_couriers,
       total_users,
       total_couriers,
       round((new_users - lag(new_users) OVER (ORDER BY date)) / lag(new_users::decimal) OVER (ORDER BY date) * 100,
             2) new_users_change,
       round((new_couriers - lag(new_couriers) OVER (ORDER BY date)) / lag(new_couriers::decimal) OVER (ORDER BY date) * 100,
             2) new_couriers_change,
       round((total_users - lag(total_users) OVER (ORDER BY date)) / lag(total_users::decimal) OVER (ORDER BY date) * 100,
             2) total_users_growth,
       round((total_couriers - lag(total_couriers) OVER (ORDER BY date)) / lag(total_couriers::decimal) OVER (ORDER BY date) * 100,
                                                                                                                                                                  2) total_couriers_growth FROM(SELECT min_date as date,
                                     users_count new_users,
                                     couriers_count new_couriers,
                                     sum(users_count) OVER (ORDER BY min_date)::int total_users,
                                     sum(couriers_count) OVER (ORDER BY min_date)::int total_couriers
                              FROM   (SELECT users_count,
                                             min_date,
                                             couriers_count
                                      FROM   time_user
                                          INNER JOIN time_courier using(min_date)) t2) t3
ORDER BY 1


--TASK 3
/*Для каждого дня, представленного в таблицах user_actions и courier_actions, рассчитайте следующие показатели:

Число платящих пользователей.
Число активных курьеров.
Долю платящих пользователей в общем числе пользователей на текущий день.
Долю активных курьеров в общем числе курьеров на текущий день.*/

with paying_users as (SELECT count(distinct user_id) as paying_users,
                             date(time) date
                      FROM   user_actions
                      WHERE  order_id not in (SELECT order_id
                                              FROM   user_actions
                                              WHERE  action = 'cancel_order')
                      GROUP BY date(time)), total_users as (SELECT count(user_id) new_users,
                                             date FROM(SELECT user_id,
                                                       min(date(time)) as date
                                                FROM   user_actions
                                                GROUP BY 1) t3
                                      GROUP BY 2), total_couriers as (SELECT count(courier_id) total_couriers,
                                       date FROM(SELECT courier_id,
                                                 min(date(time)) as date
                                          FROM   courier_actions
                                          GROUP BY 1) t4
                                GROUP BY 2), active_couriers as (SELECT count(distinct courier_id) active_couriers,
                                        date(time) date
                                 FROM   courier_actions
                                 WHERE  order_id in (SELECT order_id
                                                     FROM   courier_actions
                                                     WHERE  action = 'deliver_order')
                                 GROUP BY date(time))
SELECT date,
       paying_users,
       active_couriers,
       round(paying_users / sum(new_users) OVER (ORDER BY date)::decimal * 100,
             2) as paying_users_share,
       round(active_couriers / sum(total_couriers) OVER (ORDER BY date)::decimal * 100,
             2) as active_couriers_share
FROM   paying_users join active_couriers using(date) join total_users using(date) join total_couriers using(date)
ORDER BY 1
  
  
--TASK 4
/*Для каждого дня, представленного в таблице user_actions, рассчитайте следующие показатели:

Долю пользователей, сделавших в этот день всего один заказ, в общем количестве платящих пользователей.
Долю пользователей, сделавших в этот день несколько заказов, в общем количестве платящих пользователей.*/

with paying_users as (SELECT count(distinct user_id) as paying_users,
                             date(time) date
                      FROM   user_actions
                      WHERE  order_id not in (SELECT order_id
                                              FROM   user_actions
                                              WHERE  action = 'cancel_order')
                      GROUP BY date(time)), one_order as (SELECT date,
                                           count(distinct user_id) one_order_users
                                    FROM   (SELECT date(time) date,
                                                   user_id,
                                                   count(order_id) as count_order
                                            FROM   user_actions
                                            WHERE  order_id not in (SELECT order_id
                                                                    FROM   user_actions
                                                                    WHERE  action = 'cancel_order')
                                            GROUP BY 1, 2) t
                                    WHERE  count_order = 1
                                    GROUP BY 1), mul_order as (SELECT date,
                                  count(distinct user_id) mul_order_users
                           FROM   (SELECT date(time) date,
                                          user_id,
                                          count(order_id) as count_order_mul
                                   FROM   user_actions
                                   WHERE  order_id not in (SELECT order_id
                                                           FROM   user_actions
                                                           WHERE  action = 'cancel_order')
                                   GROUP BY 1, 2) t1
                           WHERE  count_order_mul > 1
                           GROUP BY 1)
SELECT date,
       round(one_order_users / paying_users::decimal * 100, 2) single_order_users_share,
       round(mul_order_users / paying_users::decimal * 100, 2) several_orders_users_share
FROM   mul_order join one_order using(date) join paying_users using(date)
ORDER BY 1


--TASK 5
/*Для каждого дня, представленного в таблице user_actions, рассчитайте следующие показатели:

Общее число заказов.
Число первых заказов (заказов, сделанных пользователями впервые).
Число заказов новых пользователей (заказов, сделанных пользователями в тот же день, когда они впервые воспользовались сервисом).
Долю первых заказов в общем числе заказов (долю п.2 в п.1).
Долю заказов новых пользователей в общем числе заказов (долю п.3 в п.1).*/


with all_orders_day as (SELECT date(time) date,
                               count(order_id) orders
                        FROM   user_actions
                        WHERE  order_id not in (SELECT order_id
                                                FROM   user_actions
                                                WHERE  action = 'cancel_order')
                        GROUP BY 1), first_orders as (SELECT date,
                                     count(order_id) first_orders
                              FROM   (SELECT date(time) date ,
                                             user_id,
                                             order_id,
                                             row_number() OVER(PARTITION BY user_id
                                                               ORDER BY date(time)) as rank
                                      FROM   user_actions
                                      WHERE  order_id not in (SELECT order_id
                                                              FROM   user_actions
                                                              WHERE  action = 'cancel_order')) t
                              WHERE  rank = 1
                              GROUP BY 1), new_users_orders as (SELECT t3.date,
                                         count(order_id) as new_users_orders FROM(SELECT min(date(time)) date,
                                                                                  user_id
                                                                           FROM   user_actions
                                                                           GROUP BY 2) t3
                                      LEFT JOIN (SELECT date(time) date,
                                                        user_id,
                                                        order_id
                                                 FROM   user_actions
                                                 WHERE  order_id not in (SELECT order_id
                                                                         FROM   user_actions
                                                                         WHERE  action = 'cancel_order'))t4
                                          ON t3.date = t4.date and
                                             t3.user_id = t4.user_id
                                  GROUP BY 1)
SELECT date,
       orders,
       first_orders,
       new_users_orders,
       round(first_orders / orders::decimal * 100, 2) as first_orders_share,
       round(new_users_orders / orders::decimal * 100, 2) as new_users_orders_share
FROM   all_orders_day join first_orders using(date) join new_users_orders using(date)
ORDER BY 1
  


--TASK 6
/*На основе данных в таблицах user_actions, courier_actions и orders для каждого дня рассчитайте следующие показатели:

Число платящих пользователей на одного активного курьера.
Число заказов на одного активного курьера.*/


with paying_users as (SELECT count(distinct user_id) as paying_users,
                             date(time) date
                      FROM   user_actions
                      WHERE  order_id not in (SELECT order_id
                                              FROM   user_actions
                                              WHERE  action = 'cancel_order')
                      GROUP BY date(time)), all_orders_day as (SELECT date(time) date,
                                                count(order_id) orders
                                         FROM   user_actions
                                         WHERE  order_id not in (SELECT order_id
                                                                 FROM   user_actions
                                                                 WHERE  action = 'cancel_order')
                                         GROUP BY 1), active_couriers as (SELECT count(distinct courier_id) active_couriers,
                                        date(time) date
                                 FROM   courier_actions
                                 WHERE  order_id in (SELECT order_id
                                                     FROM   courier_actions
                                                     WHERE  action = 'deliver_order')
                                 GROUP BY date(time))
SELECT date,
       round(paying_users / active_couriers::decimal, 2) as users_per_courier,
       round(orders / active_couriers::decimal, 2) as orders_per_courier
FROM   paying_users join all_orders_day using(date) join active_couriers using(date)
ORDER BY 1



--TASK 7
/*На основе данных в таблице courier_actions для каждого дня рассчитайте, за сколько минут в среднем курьеры доставляли свои заказы.

Колонку с показателем назовите minutes_to_deliver. Колонку с датами назовите date. При расчёте среднего времени доставки округляйте количество минут до целых значений. Учитывайте только доставленные заказы, отменённые заказы не учитывайте.

Результирующая таблица должна быть отсортирована по возрастанию даты.*/

with deliver_orders_by_date as(SELECT time as deliver_time,
                                      order_id,
                                      date(time) as date
                               FROM   courier_actions
                               WHERE  action = 'deliver_order'), accept_orders_by_date as(SELECT time as accept_time,
                                                                  order_id,
                                                                  date(time) as date
                                                           FROM   courier_actions
                                                           WHERE  action = 'accept_order')
SELECT date,
       avg(time_to_deliver / 60)::int as minutes_to_deliver FROM(SELECT deliver_orders_by_date.date as date,
                                                                 deliver_time,
                                                                 accept_time,
                                                                 extract(epoch
                                                          FROM   age(deliver_time, accept_time)) time_to_deliver, order_id
                                                          FROM   deliver_orders_by_date join accept_orders_by_date using(order_id))t
GROUP BY 1
ORDER BY 1



--TASK 8
/*На основе данных в таблице orders для каждого часа в сутках рассчитайте следующие показатели:

Число успешных (доставленных) заказов.
Число отменённых заказов.
Долю отменённых заказов в общем числе заказов (cancel rate).*/

with count_deliver as (SELECT date_part('hour', creation_time)::int as hour,
                              count(order_id) count_deliver
                       FROM   orders join courier_actions using(order_id)
                       WHERE  action = 'deliver_order'
                       GROUP BY 1), count_canceled as (SELECT date_part('hour', creation_time)::int as hour,
                                       count(order_id) count_canceled
                                FROM   orders join user_actions using(order_id)
                                WHERE  action = 'cancel_order'
                                GROUP BY 1), count_orders as (SELECT date_part('hour', creation_time)::int as hour,
                                     count(order_id) count_orders
                              FROM   orders
                              GROUP BY 1)
SELECT hour,
       count_deliver as successful_orders,
       count_canceled as canceled_orders,
       round(count_canceled / count_orders::decimal, 3) as cancel_rate
FROM   count_deliver join count_canceled using(hour) join count_orders using(hour)
ORDER BY 1
