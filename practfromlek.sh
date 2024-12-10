#!/bin/bash

# Функция для вывода справки по использованию скрипта
print_help() {
    echo "Using: $0 [options]"
    echo ""
    echo "Options"
    echo "  -u, --users            Выводит перечень пользователей и их домашних директорий."
    echo "  -p, --processes        Выводит перечень запущенных процессов."
    echo "  -h, --help             Выводит данную справку."
    echo "  -l PATH, --log PATH    Записывает вывод в файл по заданному пути."
    echo "  -e PATH, --errors PATH Записывает ошибки в файл ошибок по заданному пути."
}

# Инициализация переменных для путей
log_PATH=""
error_PATH=""
action=""

# Функция для вывода пользователей и их домашних директорий
list_users() {
    awk -F: '$3>=1000 { print $1 " " $6 }' /etc/passwd | sort
}

# Функция для вывода запущенных процессов
list_processes() {
    ps -Ao pid,comm --sort=pid
}

# Обработка аргументов командной строки
while getopts ":uphl:e:-:" opt; do
    case $opt in
        u)
            action="users"
            ;;
        p)
            action="processes"
            ;;
        h)
            action="help"
            print_help
            exit 0
            ;;
        l)
            log_PATH="$OPTARG"
            ;;
        e)
            error_PATH="$OPTARG"
            ;;
        -)
            case "${OPTARG}" in
                users)
                    action="users"
                    ;;
                processes)
                    action="processes"
                    ;;
                help)
                    action="help"
                    print_help
                    exit 0
                    ;;
                log)
                    log_PATH="${!OPTIND}"; OPTIND=$(( OPTIND + 1 ))
                    ;;
                errors)
                    error_PATH="${!OPTIND}"; OPTIND=$(( OPTIND + 1 ))
                    ;;
                *)
                    error_message="Нет такого флага: --${OPTARG}"
                    if [ -n "$error_PATH" ]; then
                        echo "$error_message" >> "$error_PATH"  # Запись ошибки в файл ошибок
                    else
                        echo "$error_message" >&2  # Вывод ошибки в терминал
                    fi
                    exit 1
                    ;;
            esac
            ;;
        ?)
            error_message="Нет такого флага: -$OPTARG"
            if [ -n "$error_PATH" ]; then
                echo "$error_message" >> "$error_PATH"  # Запись ошибки в файл ошибок
            else
                echo "$error_message" >&2  # Вывод ошибки в терминал
            fi
            exit 1
            ;;
        :)
            error_message="Отсутствует аргумент для флага: -$OPTARG"
            if [ -n "$error_PATH" ]; then
                echo "$error_message" >> "$error_PATH"  # Запись ошибки в файл ошибок
            else
                echo "$error_message" >&2  # Вывод ошибки в терминал
            fi
            exit 1
            ;;
    esac
done

# Проверка на отсутствие действия (если ни один флаг не был указан)
if [[ -z "$action" ]]; then
    error_message="Ошибка: Действие не задано."
    if [ -n "$error_PATH" ]; then
        echo "$error_message" >> "$error_PATH"  # Запись ошибки в файл ошибок
    else
        echo "$error_message" >&2  # Вывод ошибки в терминал
    fi
    exit 1
fi

# Выполнение действия в зависимости от выбранного аргумента
if [ -n "$log_PATH" ]; then
    if [ -w "$log_PATH" ] || [ ! -e "$log_PATH" ]; then
        {
            case $action in
                users) list_users ;;  # Вызов функции для вывода пользователей
                processes) list_processes ;;  # Вызов функции для вывода процессов
                help) print_help ;;  # Вызов функции справки
                *)
                    exit 1  # Неверное действие, выход с ошибкой
                    ;;
            esac
        } >> "$log_PATH"  # Перенаправление вывода в указанный файл лога
    else        
        echo "Error: Cannot write to log path $log_PATH" >&2  # Ошибка записи в файл лога
        exit 1
    fi
else
    default_log_file="logi.log"  # Имя файла по умолчанию для лога
    {
        case $action in
            users) list_users ;;  # Вызов функции для вывода пользователей
            processes) list_processes ;;  # Вызов функции для вывода процессов
            help) print_help ;;  # Вызов функции справки
            *)
                exit 1  # Неверное действие, выход с ошибкой
                ;;
        esac
    } >> "$default_log_file"  # Перенаправление вывода в файл по умолчанию лога
fi

# Если не указаны флаги -l или -e, выводим результат в терминал
if [ -z "$log_PATH" ] && [ -z "$error_PATH" ]; then
    case $action in
        users) list_users ;;  # Вызов функции для вывода пользователей
        processes) list_processes ;;  # Вызов функции для вывода процессов
        help) print_help ;;  # Вызов функции справки
        *)
            exit 1  # Неверное действие, выход с ошибкой
            ;;
    esac
fi

# Обработка случая, когда не указано действие (action пуст)
if [ -z "$action" ]; then
    error_message="Ошибка: Не указано действие."
    if [ -n "$error_PATH" ]; then
        echo "$error_message" >> "$error_PATH"  # Запись ошибки в файл ошибок
    else
        echo "$error_message" >&2  # Вывод ошибки в терминал
    fi
    exit 1
fi
