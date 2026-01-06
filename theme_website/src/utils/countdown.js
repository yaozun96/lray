// utils/countdown.js

export const setFutureTime = (hours = 10) => {
    const currentTime = new Date();
    const futureTime = new Date(currentTime.getTime() + hours * 60 * 60 * 1000);
    localStorage.setItem('endTime', futureTime.toISOString());
    return futureTime;
};

export const getFutureTime = () => {
    return localStorage.getItem('endTime');
};

export const getRemainingTime = (endTime) => {
    const now = new Date().getTime();
    const remainingTime = new Date(endTime).getTime() - now;

    if (remainingTime < 0) {
        return '已过期';
    }

    const hours = Math.floor((remainingTime % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
    const minutes = Math.floor((remainingTime % (1000 * 60 * 60)) / (1000 * 60));
    const seconds = Math.floor((remainingTime % (1000 * 60)) / 1000);

    return `00:0${hours}:${minutes}:${seconds}`;
};