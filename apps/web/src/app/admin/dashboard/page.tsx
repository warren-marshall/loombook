import styles from "./page.module.css";

export default function AdminHome() {
  return (
    <div className={styles.page}>
      <div className={styles.brief}>
        <div className={styles.heading}>Daily brief</div>
      </div>
      <div className={styles.dailylight}>Today&apos;s light</div>
      <div className={styles.kanban}>Kanban</div>
      <div className={styles.nextshoot}>Next shoot</div>
    </div>
  );
}